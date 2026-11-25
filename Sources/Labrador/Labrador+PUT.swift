//
// Motley – Michael's Swift Toolkit
// Copyright 2025-2026 Wells Consulting.
//

import Foundation

// MARK: - PUT

public extension Labrador {

    /// PUTs to a URL with no body and returns the response body.
    func put(
        _ url: URL,
        headers: [String: String]? = nil,
        timeout: TimeInterval? = nil,
        logging: LogOptions? = nil,
        logContext: String? = nil,
    ) async throws -> Data? {

        try await request(
            url: url,
            method: .put,
            headers: headers,
            timeout: timeout,
            logging: logging,
            logContext: logContext,
        ).0
    }

    /// PUTs raw data and decodes the response as `outputType`.
    func put<Output: Decodable>(
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
            method: .put,
            data: data,
            outputType: outputType,
            headers: headers,
            timeout: timeout,
            userInfo: userInfo,
            logging: logging,
            logContext: logContext,
        )
    }

    /// PUTs a JSON value and returns the response body.
    func put(
        _ url: URL,
        body input: some Encodable,
        headers: [String: String]? = nil,
        timeout: TimeInterval? = nil,
        logging: LogOptions? = nil,
        logContext: String? = nil,
    ) async throws -> Data? {

        try await request(
            url: url,
            method: .put,
            input: input,
            headers: headers,
            timeout: timeout,
            logging: logging,
            logContext: logContext,
        ).0
    }

    /// PUTs a JSON value and decodes the response as `outputType`.
    func put<Output: Decodable>(
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
            method: .put,
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
