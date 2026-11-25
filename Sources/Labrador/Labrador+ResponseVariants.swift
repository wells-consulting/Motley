//
// Motley – Michael's Swift Toolkit
// Copyright 2025-2026 Wells Consulting.
//

import Foundation

// MARK: - Response Variants

/// Overloads that return ``Response<Output>`` instead of bare `Output`,
/// giving callers access to response headers, status codes, etc.
public extension Labrador {

    /// GETs a URL and returns the decoded value with the HTTP response.
    func getWithResponse<Output: Decodable>(
        _ url: URL,
        as outputType: Output.Type,
        headers: [String: String]? = nil,
        timeout: TimeInterval? = nil,
        userInfo: [CodingUserInfoKey: any Sendable]? = nil,
        logging: LogOptions? = nil,
        logContext: String? = nil,
    ) async throws -> Response<Output> {

        let payload: Payload? = nil

        let clientRequest = ClientRequest(
            url: url,
            method: .get,
            payload: payload,
            accept: .json,
            logOptions: logging,
            headers: headers,
            timeout: timeout,
            logContext: logContext,
        )

        return try await requestWithResponse(
            clientRequest,
            outputType: outputType,
            userInfo: userInfo
        )
    }

    /// POSTs a JSON value and returns the decoded value with the HTTP response.
    func postWithResponse<Output: Decodable>(
        _ url: URL,
        body input: some Encodable,
        as outputType: Output.Type,
        headers: [String: String]? = nil,
        timeout: TimeInterval? = nil,
        userInfo: [CodingUserInfoKey: any Sendable]? = nil,
        logging: LogOptions? = nil,
        logContext: String? = nil,
    ) async throws -> Response<Output> {

        let data = try jayson.encode(input, userInfo: userInfo)

        let payload = Payload(
            data: data,
            contentType: .json,
            typeName: "\(type(of: input))",
            summary: ((input as? (any SummaryProviding))?.summary) ?? data.summary,
        )

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

        return try await requestWithResponse(
            clientRequest,
            outputType: outputType,
            userInfo: userInfo
        )
    }

    /// PUTs a JSON value and returns the decoded value with the HTTP response.
    func putWithResponse<Output: Decodable>(
        _ url: URL,
        body input: some Encodable,
        as outputType: Output.Type,
        headers: [String: String]? = nil,
        timeout: TimeInterval? = nil,
        userInfo: [CodingUserInfoKey: any Sendable]? = nil,
        logging: LogOptions? = nil,
        logContext: String? = nil,
    ) async throws -> Response<Output> {

        let data = try jayson.encode(input, userInfo: userInfo)

        let payload = Payload(
            data: data,
            contentType: .json,
            typeName: "\(type(of: input))",
            summary: ((input as? (any SummaryProviding))?.summary) ?? data.summary,
        )

        let clientRequest = ClientRequest(
            url: url,
            method: .put,
            payload: payload,
            accept: .json,
            logOptions: logging,
            headers: headers,
            timeout: timeout,
            logContext: logContext,
        )

        return try await requestWithResponse(
            clientRequest,
            outputType: outputType,
            userInfo: userInfo
        )
    }

    /// PATCHes a JSON value and returns the decoded value with the HTTP response.
    func patchWithResponse<Output: Decodable>(
        _ url: URL,
        body input: some Encodable,
        as outputType: Output.Type,
        headers: [String: String]? = nil,
        timeout: TimeInterval? = nil,
        userInfo: [CodingUserInfoKey: any Sendable]? = nil,
        logging: LogOptions? = nil,
        logContext: String? = nil,
    ) async throws -> Response<Output> {

        let data = try jayson.encode(input, userInfo: userInfo)

        let payload = Payload(
            data: data,
            contentType: .json,
            typeName: "\(type(of: input))",
            summary: ((input as? (any SummaryProviding))?.summary) ?? data.summary,
        )

        let clientRequest = ClientRequest(
            url: url,
            method: .patch,
            payload: payload,
            accept: .json,
            logOptions: logging,
            headers: headers,
            timeout: timeout,
            logContext: logContext,
        )

        return try await requestWithResponse(
            clientRequest,
            outputType: outputType,
            userInfo: userInfo
        )
    }

    /// DELETEs with a JSON value and returns the decoded value with the HTTP
    /// response.
    func deleteWithResponse<Output: Decodable>(
        _ url: URL,
        body input: some Encodable,
        as outputType: Output.Type,
        headers: [String: String]? = nil,
        timeout: TimeInterval? = nil,
        userInfo: [CodingUserInfoKey: any Sendable]? = nil,
        logging: LogOptions? = nil,
        logContext: String? = nil,
    ) async throws -> Response<Output> {

        let data = try jayson.encode(input, userInfo: userInfo)

        let payload = Payload(
            data: data,
            contentType: .json,
            typeName: "\(type(of: input))",
            summary: ((input as? (any SummaryProviding))?.summary) ?? data.summary,
        )

        let clientRequest = ClientRequest(
            url: url,
            method: .delete,
            payload: payload,
            accept: .json,
            logOptions: logging,
            headers: headers,
            timeout: timeout,
            logContext: logContext,
        )

        return try await requestWithResponse(
            clientRequest,
            outputType: outputType,
            userInfo: userInfo
        )
    }

    // MARK: - Data Response Variants

    /// POSTs raw data and returns the response with the raw body.
    func postWithResponse(
        _ url: URL,
        data: Data,
        contentType: ContentType = .binary,
        headers: [String: String]? = nil,
        timeout: TimeInterval? = nil,
        logging: LogOptions? = nil,
        logContext: String? = nil,
    ) async throws -> Response<Data> {

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

        return try await requestWithDataResponse(clientRequest)
    }

    /// POSTs a multipart form and returns the response with the raw body.
    func postWithResponse(
        _ url: URL,
        form: MultipartForm,
        headers: [String: String]? = nil,
        timeout: TimeInterval? = nil,
        logging: LogOptions? = nil,
        logContext: String? = nil,
    ) async throws -> Response<Data> {

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

        return try await requestWithDataResponse(clientRequest)
    }

    /// POSTs a URL-encoded form and returns the response with the raw body.
    func postWithResponse(
        _ url: URL,
        form: URLEncodedForm,
        headers: [String: String]? = nil,
        timeout: TimeInterval? = nil,
        logging: LogOptions? = nil,
        logContext: String? = nil,
    ) async throws -> Response<Data> {

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

        return try await requestWithDataResponse(clientRequest)
    }
}
