//
// Motley – Michael's Swift Toolkit
// Copyright 2025-2026 Wells Consulting.
//

import Foundation

// MARK: - PATCH

public extension Labrador {

    /// PATCHes a URL with no body and returns the response body.
    func patch(
        _ url: URL,
        headers: [String: String]? = nil,
        timeout: TimeInterval? = nil,
        logging: LogOptions? = nil,
        logContext: String? = nil,
    ) async throws -> Data? {

        try await request(
            url: url,
            method: .patch,
            headers: headers,
            timeout: timeout,
            logging: logging,
            logContext: logContext,
        ).0
    }

    /// PATCHes raw data and decodes the response as `outputType`.
    func patch<Output: Decodable>(
        _ url: URL,
        data: Data,
        as outputType: Output.Type,
        headers: [String: String]? = nil,
        timeout: TimeInterval? = nil,
        userInfo: [CodingUserInfoKey: any Sendable]? = nil,
        logging: LogOptions? = nil,
        logContext: String? = nil,
    ) async throws -> Output {

        try await request(
            url: url,
            method: .patch,
            data: data,
            outputType: outputType,
            headers: headers,
            timeout: timeout,
            userInfo: userInfo,
            logging: logging,
            logContext: logContext,
        )
    }

    /// PATCHes a JSON value and returns the response body.
    func patch(
        _ url: URL,
        body input: some Encodable,
        headers: [String: String]? = nil,
        timeout: TimeInterval? = nil,
        logging: LogOptions? = nil,
        logContext: String? = nil,
    ) async throws -> Data? {

        try await request(
            url: url,
            method: .patch,
            input: input,
            headers: headers,
            timeout: timeout,
            logging: logging,
            logContext: logContext,
        ).0
    }

    /// PATCHes a JSON value and decodes the response as `outputType`.
    func patch<Output: Decodable>(
        _ url: URL,
        body input: some Encodable,
        as outputType: Output.Type,
        headers: [String: String]? = nil,
        timeout: TimeInterval? = nil,
        userInfo: [CodingUserInfoKey: any Sendable]? = nil,
        logging: LogOptions? = nil,
        logContext: String? = nil,
    ) async throws -> Output {

        try await request(
            url: url,
            method: .patch,
            input: input,
            outputType: outputType,
            headers: headers,
            timeout: timeout,
            userInfo: userInfo,
            logging: logging,
            logContext: logContext,
        )
    }
}
