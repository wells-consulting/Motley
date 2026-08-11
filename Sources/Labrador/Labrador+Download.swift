//
// Copyright 2025-2026 Wells Consulting.
// This file is part of Motley and is released under the MIT License.
//

import Foundation

#if canImport(FoundationNetworking)
    import FoundationNetworking
#endif

// MARK: - Download

extension Labrador {

    public enum DownloadEvent: Sendable {
        case progress(bytesReceived: Int64, totalBytes: Int64?)
        case completed(Data)
        case failed(any Error)
    }

    public func downloadInMemory(
        _ url: URL,
        headers: [String: String]? = nil,
        timeout: TimeInterval? = nil,
        logContext: String? = nil,
    ) -> AsyncStream<DownloadEvent> {

        let clientRequest = ClientRequest(
            url: url,
            method: .get,
            payload: nil,
            headers: headers,
            timeout: timeout
        )

        log(clientRequest)

        let urlRequest = urlRequestWithUpdatedHeaders(from: clientRequest)

        let urlSession = urlSession

        return AsyncStream { continuation in
            let task = Task {
                do {
                    let (data, urlResponse) = try await urlSession.data(for: urlRequest)

                    let totalBytes: Int64? = {
                        let expected = urlResponse.expectedContentLength
                        return expected != -1 ? expected : nil
                    }()

                    let bytesReceived = Int64(data.count)

                    continuation.yield(.progress(bytesReceived: bytesReceived, totalBytes: totalBytes))
                    continuation.yield(.completed(data))

                } catch is CancellationError {
                    // Stream was cancelled; nothing to yield
                } catch {
                    continuation.yield(.failed(error))
                }

                continuation.finish()
            }

            continuation.onTermination = { _ in
                task.cancel()
            }
        }
    }

    // MARK: - File Download

    public enum FileDownloadEvent: Sendable {
        case progress(bytesWritten: Int64, totalBytes: Int64?, speed: Double?)
        case completed(tempFileURL: URL)
        case cancelled(resumeData: Data?)
        case failed(any Error)
    }

    public struct FileDownloadTransfer: Sendable {
        public let events: AsyncStream<FileDownloadEvent>
        public let cancelProducingResumeData: @Sendable () async -> Data?
        public let cancel: @Sendable () -> Void
    }

    private final class FileDownloadTaskController: @unchecked Sendable {
        private let lock = NSLock()
        private var didCancel = false

        private let downloadTask: URLSessionDownloadTask
        private let sessionDelegate: LabradorSessionDelegate?

        init(
            downloadTask: URLSessionDownloadTask,
            sessionDelegate: LabradorSessionDelegate?
        ) {
            self.downloadTask = downloadTask
            self.sessionDelegate = sessionDelegate
        }

        func cancel() {
            guard beginCancel() else { return }
            sessionDelegate?.unregister(for: downloadTask.taskIdentifier)
            downloadTask.cancel()
        }

        func cancelProducingResumeData() async -> Data? {
            guard beginCancel() else { return nil }

            sessionDelegate?.unregister(for: downloadTask.taskIdentifier)

            return await withCheckedContinuation { continuation in
                downloadTask.cancel { resumeData in
                    continuation.resume(returning: resumeData)
                }
            }
        }

        private func beginCancel() -> Bool {
            lock.lock()
            defer { lock.unlock() }

            guard !didCancel else { return false }
            didCancel = true
            return true
        }
    }

    /// Downloads a resource directly to disk via `URLSessionDownloadTask`.
    ///
    /// Use this instead of ``downloadInMemory(_:headers:timeout:logContext:)``
    /// for large files where buffering the entire response in memory is not
    /// acceptable.
    ///
    /// The caller is responsible for moving `tempFileURL` to its final destination
    /// when handling the `.completed` event — the URL is stable across the event
    /// loop but will be cleaned up on the next system temp-directory sweep.
    public func downloadToFile(
        _ request: URLRequest,
        resumeData: Data? = nil,
        timeout: TimeInterval? = nil,
        progressThrottleInterval: TimeInterval? = nil,
        logContext: String? = nil
    ) -> FileDownloadTransfer {
        let clientRequest = ClientRequest(
            urlRequest: request,
            logContext: logContext
        )

        log(clientRequest)

        let sessionDelegate = sessionDelegate
        let session = urlSession
        let throttleInterval = progressThrottleInterval ?? 0.5

        var controller: FileDownloadTaskController?

        let events = AsyncStream<FileDownloadEvent> { continuation in
            let downloadTask: URLSessionDownloadTask
            if let resumeData {
                downloadTask = session.downloadTask(withResumeData: resumeData)
            } else {
                downloadTask = session.downloadTask(with: request)
            }

            let taskController = FileDownloadTaskController(
                downloadTask: downloadTask,
                sessionDelegate: sessionDelegate
            )

            controller = taskController

            sessionDelegate?.register(
                continuation,
                progressThrottleInterval: throttleInterval,
                for: downloadTask.taskIdentifier
            )

            downloadTask.resume()

            continuation.onTermination = { @Sendable reason in
                switch reason {
                case .cancelled:
                    taskController.cancel()
                case .finished:
                    break
                @unknown default:
                    taskController.cancel()
                }
            }
        }

        let _controller = controller

        return FileDownloadTransfer(
            events: events,
            cancelProducingResumeData: {
                await _controller?.cancelProducingResumeData()
            },
            cancel: {
                _controller?.cancel()
            }
        )
    }
}
