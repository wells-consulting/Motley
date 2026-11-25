//
// Motley – Michael's Swift Toolkit
// Copyright 2025-2026 Wells Consulting.
//

import Foundation

// MARK: - POST

public extension Labrador {

    /// POSTs to a URL with no body and returns the response body.
    func post(
        _ url: URL,
        headers: [String: String]? = nil,
        timeout: TimeInterval? = nil,
        logging: LogOptions? = nil,
        logContext: String? = nil,
    ) async throws -> Data? {

        try await request(
            url: url,
            method: .post,
            headers: headers,
            timeout: timeout,
            logging: logging,
            logContext: logContext,
        ).0
    }

    /// POSTs raw data and returns the response body.
    func post(
        _ url: URL,
        data: Data,
        contentType: ContentType = .binary,
        headers: [String: String]? = nil,
        timeout: TimeInterval? = nil,
        logging: LogOptions? = nil,
        logContext: String? = nil,
    ) async throws -> Data? {

        let payload = Payload(
            data: data,
            contentType: contentType,
            typeName: "\(Data.self)",
            summary: data.count.formatted(.byteCount(style: .memory)),
        )

        let clientRequest = ClientRequest(
            url: url,
            method: .post,
            payload: payload,
            accept: .binary,
            logOptions: logging,
            headers: headers,
            timeout: timeout,
            logContext: logContext,
        )

        return try await dispatch(clientRequest).0
    }

    /// POSTs raw data and decodes the response as `outputType`.
    func post<Output: Decodable>(
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
            method: .post,
            data: data,
            outputType: outputType,
            headers: headers,
            timeout: timeout,
            userInfo: userInfo,
            logging: logging,
            logContext: logContext,
        )
    }

    /// POSTs a JSON value and returns the response body.
    func post(
        _ url: URL,
        body input: some Encodable,
        headers: [String: String]? = nil,
        timeout: TimeInterval? = nil,
        logging: LogOptions? = nil,
        logContext: String? = nil,
    ) async throws -> Data? {

        try await request(
            url: url,
            method: .post,
            input: input,
            headers: headers,
            timeout: timeout,
            logging: logging,
            logContext: logContext,
        ).0
    }

    /// POSTs a JSON value and decodes the response as `outputType`.
    func post<Output: Decodable>(
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
            method: .post,
            input: input,
            outputType: outputType,
            headers: headers,
            timeout: timeout,
            userInfo: userInfo,
            logging: logging,
            logContext: logContext,
        )
    }

    // MARK: MultipartForm

    /// POSTs a multipart form and returns the response body.
    func post(
        _ url: URL,
        form: MultipartForm,
        headers: [String: String]? = nil,
        timeout: TimeInterval? = nil,
        logging: LogOptions? = nil,
        logContext: String? = nil,
    ) async throws -> Data? {

        let payload = payload(for: form)

        let clientRequest = ClientRequest(
            url: url,
            method: .post,
            payload: payload,
            accept: .json,
            logOptions: logging,
            headers: headers,
            timeout: timeout,
            logContext: logContext,
        )

        return try await dispatch(clientRequest).0
    }

    /// POSTs a multipart form and decodes the response as `outputType`.
    func post<Output: Decodable>(
        _ url: URL,
        form: MultipartForm,
        as outputType: Output.Type,
        headers: [String: String]? = nil,
        timeout: TimeInterval? = nil,
        userInfo: [CodingUserInfoKey: any Sendable]? = nil,
        logging: LogOptions? = nil,
        logContext: String? = nil,
    ) async throws -> Output {

        let payload = payload(for: form)

        let clientRequest = ClientRequest(
            url: url,
            method: .post,
            payload: payload,
            accept: .json,
            logOptions: logging,
            headers: headers,
            timeout: timeout,
            logContext: logContext,
        )

        return try await request(
            clientRequest,
            outputType: outputType,
            userInfo: userInfo,
        )
    }

    // MARK: URLEncodedForm

    /// POSTs a URL-encoded form and returns the response body.
    func post(
        _ url: URL,
        form: URLEncodedForm,
        headers: [String: String]? = nil,
        timeout: TimeInterval? = nil,
        logging: LogOptions? = nil,
        logContext: String? = nil,
    ) async throws -> Data? {

        let payload = payload(for: form)

        let clientRequest = ClientRequest(
            url: url,
            method: .post,
            payload: payload,
            accept: .binary,
            logOptions: logging,
            headers: headers,
            timeout: timeout,
            logContext: logContext,
        )

        return try await dispatch(clientRequest).0
    }

    /// POSTs a URL-encoded form and decodes the response as `outputType`.
    func post<Output: Decodable>(
        _ url: URL,
        form: URLEncodedForm,
        as outputType: Output.Type,
        headers: [String: String]? = nil,
        timeout: TimeInterval? = nil,
        userInfo: [CodingUserInfoKey: any Sendable]? = nil,
        logging: LogOptions? = nil,
        logContext: String? = nil,
    ) async throws -> Output {

        let payload = payload(for: form)

        let clientRequest = ClientRequest(
            url: url,
            method: .post,
            payload: payload,
            accept: .json,
            logOptions: logging,
            headers: headers,
            timeout: timeout,
            logContext: logContext,
        )

        return try await request(
            clientRequest,
            outputType: outputType,
            userInfo: userInfo,
        )
    }
}
