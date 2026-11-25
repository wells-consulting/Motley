//
// Motley – Michael's Swift Toolkit
// Copyright 2025-2026 Wells Consulting.
//

import Foundation

/// A request that didn't finish, or finished with a status the client treats
/// as a failure.
public struct LabradorError: MotleyError {

    // MARK: - Properties

    /// A short description of the failure.
    public let summary: String

    /// The extra detail, plus the response body when there is one.
    public let details: String?

    /// The error underneath, when there is one.
    public let underlyingError: (any Error)?

    /// The request that failed.
    public let urlRequest: URLRequest?

    /// The response, when the server sent one.
    public let httpURLResponse: HTTPURLResponse?

    /// The raw response body.
    public let responseData: Data?

    /// The response body as text, truncated to 2,000 characters.
    public let responseBody: String?

    /// When the request started and finished.
    public let timing: Range<Date>?

    /// The HTTP status code, when the response has one.
    public var statusCode: Labrador.StatusCode? {
        if let statusCodeRawValue = httpURLResponse?.statusCode {
            Labrador.StatusCode(rawValue: statusCodeRawValue)
        } else {
            nil
        }
    }

    /// A response header's value.
    public func header(_ name: String) -> String? {
        httpURLResponse?.value(forHTTPHeaderField: name)
    }

    /// Decodes the response data as this type, or returns `nil`.
    ///
    /// This is a convenience for an error screen. The client already tried to
    /// decode the response once, so a failure here usually means the body isn't
    /// the type you expected.
    public func response<T: Decodable>(as type: T.Type) -> T? {
        guard let responseData else { return nil }
        // swiftlint:disable:next no_try_question
        return try? Jayson.shared.decode(T.self, from: responseData)
    }

    /// Transient for a timeout, a 429 or a 5xx, and for a dropped connection.
    /// Persistent for everything else.
    public var errorKind: ErrorKind {
        // Transient HTTP status codes (match RetryPolicy.defaultRetryCodes)
        if let statusCode {
            switch statusCode {
            case .requestTimeout, .tooManyRequests:
                return .transient
            case .internalServerError, .badGateway, .serviceUnavailable, .gatewayTimeout:
                return .transient
            default:
                return .persistent
            }
        }
        // Transient URLError codes
        if let urlError = underlyingError as? Foundation.URLError {
            switch urlError.code {
            case .timedOut, .networkConnectionLost, .notConnectedToInternet:
                return .transient
            default:
                return .persistent
            }
        }
        return .persistent
    }

    // MARK: - Lifecycle

    // MARK: Initializers

    init(
        summary: String,
        details: String? = nil,
        underlyingError: (any Error)? = nil,
        urlRequest: URLRequest? = nil,
        httpURLResponse: HTTPURLResponse? = nil,
        responseData: Data? = nil,
        responseBody: String? = nil,
        timing: Range<Date>? = nil,
    ) {

        self.summary = summary

        let truncatedBody = responseBody.map { String($0.prefix(2000)) }
        self.responseBody = truncatedBody
        if let truncatedBody, !truncatedBody.isEmpty {
            self.details = details.map { $0 + "\n" + truncatedBody } ?? truncatedBody
        } else {
            self.details = details
        }

        self.underlyingError = underlyingError

        self.urlRequest = urlRequest
        self.httpURLResponse = httpURLResponse
        self.responseData = responseData
        self.timing = timing
    }

    init(
        summary: String,
        details: String? = nil,
        underlyingError: (any Error)? = nil,
        userInfo: [String: any Sendable]? = nil,
        clientRequest: Labrador.ClientRequest,
        httpURLResponse: HTTPURLResponse? = nil,
        responseData: Data? = nil,
        responseBody: String? = nil,
        timing: Range<Date>? = nil,
    ) {

        self.summary = summary

        let truncatedBody = responseBody.map { String($0.prefix(2000)) }
        self.responseBody = truncatedBody
        if let truncatedBody, !truncatedBody.isEmpty {
            self.details = details.map { $0 + "\n" + truncatedBody } ?? truncatedBody
        } else {
            self.details = details
        }

        self.underlyingError = underlyingError

        self.urlRequest = clientRequest.urlRequest
        self.httpURLResponse = httpURLResponse
        self.responseData = responseData
        self.timing = timing
    }

    // MARK: Factory Methods

    /// An error for a request that has no URL.
    public static func noURL() -> Self {
        LabradorError(
            summary: "Request has no URL.",
        )
    }
}
