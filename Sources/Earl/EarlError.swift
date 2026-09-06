//
// Motley – Michael's Swift Toolkit
// Copyright 2025-2026 Wells Consulting.
//

import Foundation

public struct EarlError: MotleyError {

    // MARK: - Properties

    public let summary: String
    public let details: String?
    public let underlyingError: (any Error)?
    public var errorKind: ErrorKind { .configuration }

    public let urlString: String?
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
