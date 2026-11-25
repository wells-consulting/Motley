//
// Motley – Michael's Swift Toolkit
// Copyright 2025-2026 Wells Consulting.
//

import Foundation

// MARK: - Upload

public extension Labrador {

    /// What an upload reports as it runs.
    enum UploadEvent: Sendable {
        /// Some bytes were sent. `totalBytes` is `nil` when the size isn't
        /// known.
        case progress(bytesSent: Int64, totalBytes: Int64?)
        /// The upload finished with the response body.
        case completed(Data)
        /// The upload failed.
        case failed(any Error)
    }

    /// Uploads raw data and reports progress as it goes.
    func upload(
        _ url: URL,
        data body: Data,
        method: Method = .post,
        contentType: ContentType = .binary,
        headers: [String: String]? = nil,
        timeout: TimeInterval? = nil,
        logContext: String? = nil,
    ) -> AsyncStream<UploadEvent> {

        let summary = body.count.formatted(.byteCount(style: .binary))

        let clientRequest = ClientRequest(
            url: url,
            method: method,
            payload: .some(
                .init(
                    data: body,
                    contentType: contentType,
                    typeName: nil,
                    summary: summary
                )
            ),
            headers: headers,
            timeout: timeout,
            logContext: logContext
        )

        log(clientRequest)

        let urlRequest = urlRequestWithUpdatedHeaders(from: clientRequest)

        let urlSession = urlSession

        return AsyncStream { continuation in
            let task = Task {
                let delegate = UploadProgressDelegate(continuation: continuation)

                do {
                    let (responseData, _) = try await urlSession.upload(
                        for: urlRequest,
                        from: body,
                        delegate: delegate,
                    )

                    continuation.yield(.completed(responseData))
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

    /// Uploads a multipart form and reports progress as it goes.
    func upload(
        _ url: URL,
        form: MultipartForm,
        method: Method = .post,
        headers: [String: String]? = nil,
        timeout: TimeInterval? = nil,
        logContext: String? = nil,
    ) -> AsyncStream<UploadEvent> {
        upload(
            url,
            data: form.data,
            method: method,
            contentType: .multipartForm(MultipartForm.boundary),
            headers: headers,
            timeout: timeout,
            logContext: logContext,
        )
    }

    /// Uploads a URL-encoded form and reports progress as it goes.
    func upload(
        _ url: URL,
        form: URLEncodedForm,
        method: Method = .post,
        headers: [String: String]? = nil,
        timeout: TimeInterval? = nil,
        logContext: String? = nil,
    ) -> AsyncStream<UploadEvent> {
        upload(
            url,
            data: form.data,
            method: method,
            contentType: .urlEncodedForm,
            headers: headers,
            timeout: timeout,
            logContext: logContext,
        )
    }
}

private final class UploadProgressDelegate: NSObject, URLSessionTaskDelegate, Sendable {

    private let continuation: AsyncStream<Labrador.UploadEvent>.Continuation

    init(continuation: AsyncStream<Labrador.UploadEvent>.Continuation) {
        self.continuation = continuation
    }

    func urlSession(
        _ session: URLSession,
        task: URLSessionTask,
        didSendBodyData bytesSent: Int64,
        totalBytesSent: Int64,
        totalBytesExpectedToSend: Int64,
    ) {
        let total: Int64? =
            totalBytesExpectedToSend != NSURLSessionTransferSizeUnknown
            ? totalBytesExpectedToSend
            : nil

        continuation.yield(.progress(bytesSent: totalBytesSent, totalBytes: total))
    }
}
