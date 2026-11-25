//
// Motley – Michael's Swift Toolkit
// Copyright 2025-2026 Wells Consulting.
//

import Foundation

public extension Error {

    // MARK: Back-fill ErrorKind

    /// Extracts the `ErrorKind` from any error. Checks for `ErrorKindProviding` conformance
    /// first, then falls back to `URLError` classification, defaulting to `.persistent`.
    var errorKind: ErrorKind {
        if let kind = (self as? (any MotleyError))?.errorKind {
            return kind
        }
        if let urlError = self as? URLError {
            switch urlError.code {
            case .timedOut, .networkConnectionLost, .notConnectedToInternet,
                .cannotFindHost, .cannotConnectToHost, .dnsLookupFailed:
                return .transient
            default:
                return .persistent
            }
        }
        return .persistent
    }

    // MARK: - Describe

    /// The error as a multi-line report.
    ///
    /// Use this in a diagnostics screen or a support email. What it includes is
    /// up to `options`.
    ///
    /// - Parameters:
    ///   - options: Which parts to include.
    ///   - depth: How far down the underlying errors to indent. Callers leave
    ///     this at zero.
    func describe(
        options: ErrorDescriptionOptions,
        depth: Int = 0,
    ) -> String {

        var lines = [String]()

        let indent = String(repeating: "    ", count: depth)

        if let error = self as? (any MotleyError) {
            if depth > 0 {
                lines.append("Underlying Error (\(type(of: self)))")
            }
            lines.append(indent + error.summary)
            if options.contains(.details), let details = error.details {
                lines.append(indent + details)
            }
        } else {
            if depth > 0 {
                lines.append("Underlying Error (\(type(of: self)))")
            }
            lines.append(indent + "\(self)")
        }

        if options.contains(.nsError) {
            let nsError = self as NSError
            let domain = nsError.domain
            let skipNSError =
                domain.hasPrefix("Motley")
                || (domain == "NSCocoaErrorDomain" && nsError.code == 0)

            if !skipNSError {
                var line = "Error Domain=\(domain), Code=\(nsError.code)"
                if !nsError.userInfo.isEmpty {
                    line += " \(String(describing: nsError.userInfo))"
                }
                lines.append(indent + line)
            }
        }

        if options.contains(.underlyingError),
            let ule = (self as? (any MotleyError))?.underlyingError
        {
            lines.append(
                "\n" + ule.describe(options: options, depth: depth + 1)
            )
        }

        return lines.joined(separator: "\n")
    }

    // MARK: - URL Error Summary

    /// Returns a concise, readable summary when this error (or a wrapped underlying
    /// error) is a `URLError`. Returns `nil` for non-URL errors — callers fall back
    /// to the raw diagnostics string in that case.
    ///
    /// Example output:
    /// ```
    /// URLError -1001 (timedOut)
    /// URL: http://192.168.10.15:9999/graphql
    /// ```
    var urlErrorSummary: String? {
        let urlError: URLError

        if let e = self as? URLError {
            urlError = e
        } else if let motleyError = self as? (any MotleyError),
            let underlying = motleyError.underlyingError as? URLError
        {
            urlError = underlying
        } else {
            return nil
        }

        var lines = ["URLError \(urlError.errorCode)"]

        if let urlString = urlError.failingURL?.absoluteString {
            lines.append("URL: \(urlString)")
        }

        return lines.joined(separator: "\n")
    }
}

// MARK: - ErrorDescriptionOptions

/// What `Error.describe(options:depth:)` includes in its report.
public struct ErrorDescriptionOptions: OptionSet, Sendable {

    public let rawValue: Int
    public init(rawValue: Int) {
        self.rawValue = rawValue
    }

    /// Include the error's details.
    public static let details: Self = .init(rawValue: 1 << 2)

    /// Include the error underneath the top one.
    public static let underlyingError: Self = .init(rawValue: 1 << 3)

    /// Include the `NSError` domain and code.
    public static let nsError: Self = .init(rawValue: 1 << 5)

    /// Just the summary.
    public static let minimal: Self = []

    /// The summary and details.
    public static let basic: Self = [.details]

    /// Everything.
    public static let verbose: Self = [
        .details,
        .underlyingError,
        .nsError,
    ]
}
