//
// Motley – Michael's Swift Toolkit
// Copyright 2025-2026 Wells Consulting.
//

import Foundation

// MARK: - HEAD

public extension Labrador {

    /// Performs a HEAD request, returning only the HTTP response (no body).
    /// Useful for checking resource existence or reading response headers
    /// without downloading the body.
    /// HEADs a URL and returns the response.
    func head(
        _ url: URL,
        headers: [String: String]? = nil,
        timeout: TimeInterval? = nil,
        logging: LogOptions? = nil,
        logContext: String? = nil,
    ) async throws -> HTTPURLResponse {

        let (_, response) = try await request(
            url: url,
            method: .head,
            headers: headers,
            timeout: timeout,
            logging: logging,
            logContext: logContext,
        )

        return response
    }
}
