//
// Motley – Michael's Swift Toolkit
// Copyright 2025-2026 Wells Consulting.
//

import Foundation

/// A URL the builder couldn't make.
public struct EarlError: MotleyError {

    // MARK: - Properties

    /// A short description of what went wrong.
    public let summary: String

    /// The string and the specific problem.
    public let details: String?

    /// The error underneath, when there is one.
    public let underlyingError: (any Error)?

    /// URL problems are configuration errors.
    public var errorKind: ErrorKind { .configuration }

    /// The string the builder started with.
    public let urlString: String?

    /// The parsed pieces, when parsing got that far.
    public let urlComponents: URLComponents?

    // MARK: - Lifecycle

    // MARK: Initializer

    init(
        summary: String? = nil,
        details: String? = nil,
        underlyingError: (any Error)? = nil,
        urlString: String? = nil,
        urlComponents: URLComponents? = nil,
    ) {

        self.summary = summary ?? "Invalid URL."

        self.details = details
        self.underlyingError = underlyingError

        self.urlString = urlString
        self.urlComponents = urlComponents
    }

    // MARK: Factory Methods

    static func missingScheme(
        urlString: String,
        urlComponents: URLComponents?,
    ) -> Self {

        .init(
            summary: "Invalid URL.",
            details: "Missing scheme in \"\(urlString)\".",
            urlString: urlString,
            urlComponents: urlComponents,
        )
    }

    static func missingHost(
        urlString: String,
        urlComponents: URLComponents?,
    ) -> Self {

        .init(
            summary: "Invalid URL.",
            details: "Missing host in \"\(urlString)\".",
            urlString: urlString,
            urlComponents: urlComponents,
        )
    }

    static func invalidURL(
        urlString: String,
        urlComponents: URLComponents?,
    ) -> Self {

        .init(
            summary: "Invalid URL.",
            details: "Could not parse \"\(urlString)\".",
            urlString: urlString,
            urlComponents: urlComponents,
        )
    }
}
