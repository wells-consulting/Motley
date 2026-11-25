//
// Motley – Michael's Swift Toolkit
// Copyright 2025-2026 Wells Consulting.
//

import Foundation

// MARK: - Download

extension Labrador {

    /// What a download reports as it runs.
    public enum DownloadEvent: Sendable {
        /// Some bytes arrived. `totalBytes` is `nil` when the server didn't
        /// say how large the body is.
        case progress(bytesReceived: Int64, totalBytes: Int64?)
        /// The download finished with the whole body.
        case completed(Data)
        /// The download failed.
        case failed(any Error)
    }

    /// Downloads a URL into memory and reports progress as it goes.
    ///
    /// Use ``downloadToFile(_:resumeData:timeout:progressThrottleInterval:logContext:)``
    /// for a file too large to hold in memory.
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

                    continuation.yield(
                        .progress(bytesReceived: bytesReceived, totalBytes: totalBytes)
                    )
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

    /// What a file download reports as it runs.
    public enum FileDownloadEvent: Sendable {
        /// Some bytes were written. `totalBytes` and `speed` are `nil` when the
        /// server or the system doesn't provide them.
        case progress(bytesWritten: Int64, totalBytes: Int64?, speed: Double?)
        /// The download finished at this temporary URL. Move the file before
        /// the system clears the temporary directory.
        case completed(tempFileURL: URL)
        /// The download was canceled, with resume data when the server supports
        /// it.
        case cancelled(resumeData: Data?)
        /// The download failed.
        case failed(any Error)
    }

    /// A running file download.
    public struct FileDownloadTransfer: Sendable {
        /// The download's events.
        public let events: AsyncStream<FileDownloadEvent>
        /// Cancels the download and returns resume data, or `nil` when the
        /// server doesn't support it.
        public let cancelProducingResumeData: @Sendable () async -> Data?
        /// Cancels the download without asking for resume data.
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
