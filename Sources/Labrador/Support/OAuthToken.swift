//
// Motley – Michael's Swift Toolkit
// Copyright 2025-2026 Wells Consulting.
//

import Foundation

/// An OAuth token and the pieces that say when it expires.
///
/// `Labrador` sends ``accessToken`` as a bearer token. The rest is for the code
/// that refreshes it.
public struct OAuthToken: Codable, CustomStringConvertible, Sendable {

    /// The token to send in the `Authorization` header.
    public let accessToken: String?

    /// When the token was created. Defaults to now.
    public let createdAt: Date? = Date()

    /// How long the token lasts, in seconds.
    public let expiresIn: TimeInterval?

    /// The token used to get a new access token.
    public let refreshToken: String?

    /// The OpenID Connect ID token, when the server sends one.
    public let idToken: String?

    /// When the token expires, or `nil` when the token doesn't say.
    public var expiration: Date? {
        if let createdAt, let expiresIn {
            createdAt.addingTimeInterval(expiresIn)
        } else {
            nil
        }
    }

    /// Whether the token has expired.
    ///
    /// A token without a creation date or an expiry counts as expired, so a
    /// caller refreshes it instead of sending something it can't date.
    public var isExpired: Bool {
        if let createdAt, let expiresIn {
            -createdAt.timeIntervalSinceNow > expiresIn
        } else {
            true
        }
    }

    /// A readable summary of the token's dates. It never includes the token.
    public var description: String {
        if let createdAt, let expiresAt = expiration {
            if expiresAt < .now {
                let durationDescription = Date.durationString(from: expiresAt, to: .now)
                let text =
                    "Created on \(createdAt.formatted(date: .abbreviated, time: .shortened)), expired on \(expiresAt.formatted(date: .abbreviated, time: .shortened)) (\(durationDescription))"
                return text
            } else {
                let durationDescription = Date.durationString(from: .now, to: expiresAt)
                let text =
                    "Created on \(createdAt.formatted(date: .abbreviated, time: .shortened)), expires on \(expiresAt.formatted(date: .abbreviated, time: .shortened)) (\(durationDescription))"
                return text
            }
        } else if isExpired {
            if let expiration {
                return
                    "Authorization token expired at \(expiration.formatted(date: .abbreviated, time: .shortened))"
            } else {
                return "Authorization token expired."
            }
        } else {
            if let expiration {
                return
                    "Authorization token valid until \(expiration.formatted(date: .abbreviated, time: .shortened))"
            } else {
                return "Authorization token valid."
            }
        }
    }

    /// Creates a token from a date and its pieces.
    ///
    /// - Parameters:
    ///   - accessToken: The token to send.
    ///   - idToken: The OpenID Connect ID token.
    ///   - refreshToken: The token used to refresh this one.
    ///   - expiration: When the token expires.
    public init(
        accessToken: String?,
        idToken: String? = nil,
        refreshToken: String? = nil,
        expiration: Date? = nil
    ) {
        self.accessToken = accessToken
        self.idToken = idToken
        self.refreshToken = refreshToken
        self.expiresIn = expiration?.timeIntervalSince1970
    }

    /// Creates a token from a duration and its pieces.
    ///
    /// - Parameters:
    ///   - accessToken: The token to send.
    ///   - idToken: The OpenID Connect ID token.
    ///   - refreshToken: The token used to refresh this one.
    ///   - expiration: How long the token lasts, in seconds.
    public init(
        accessToken: String?,
        idToken: String? = nil,
        refreshToken: String? = nil,
        expiration: TimeInterval? = nil
    ) {
        self.accessToken = accessToken
        self.idToken = idToken
        self.refreshToken = refreshToken
        self.expiresIn = expiration
    }

    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case expiresIn = "expires_in"
        case refreshToken = "refresh_token"
        case idToken = "id_token"
    }

    enum GrantType {
        case authorizationCode(String)
        case refreshToken(String)

        var name: String {
            switch self {
            case .authorizationCode:
                "authorization_code"
            case .refreshToken:
                "refresh_token"
            }
        }

        var key: String {
            switch self {
            case .authorizationCode:
                "code"
            case .refreshToken:
                "refresh_token"
            }
        }

        var value: String {
            switch self {
            case let .authorizationCode(code):
                code
            case let .refreshToken(token):
                token
            }
        }
    }
}
