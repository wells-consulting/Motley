//
// Motley – Michael's Swift Toolkit
// Copyright 2025-2026 Wells Consulting.
//

import Foundation

// MARK: - GET

public extension Labrador {

    /// GETs a URL and returns the body, or `nil` when there is none.
    func get(
        _ url: URL,
        headers: [String: String]? = nil,
        timeout: TimeInterval? = nil,
        logging: LogOptions? = nil,
        logContext: String? = nil,
    ) async throws -> Data? {

        let (data, _) = try await request(
            url: url,
            method: .get,
            headers: headers,
            timeout: timeout,
            logging: logging,
            logContext: logContext,
        )

        return data
    }

    /// GETs a URL and decodes the response as `outputType`.
    func get<Output: Decodable>(
        _ url: URL,
        as outputType: Output.Type,
        headers: [String: String]? = nil,
        timeout: TimeInterval? = nil,
        userInfo: [CodingUserInfoKey: any Sendable]? = nil,
        logging: LogOptions? = nil,
        logContext: String? = nil,
    ) async throws -> Output {

        try await request(
            url: url,
            method: .get,
            data: nil,
            outputType: Output.self,
            headers: headers,
            timeout: timeout,
            userInfo: userInfo,
            logging: logging,
            logContext: logContext,
        )
    }
}
