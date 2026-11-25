//
// Motley – Michael's Swift Toolkit
// Copyright 2025-2026 Wells Consulting.
//

import Foundation

/// A value that couldn't be encoded or decoded.
public struct JaysonError: MotleyError {

    /// Which direction the coder was going.
    public enum Process: Sendable {
        /// Encoding a value.
        case encode
        /// Decoding data.
        case decode
    }

    // MARK: - Properties

    /// A short description of what went wrong.
    public let summary: String

    /// The coding path and the specific problem.
    public let details: String?

    /// The error underneath, when there is one.
    public let underlyingError: (any Error)?

    /// The coding context passed to the coder.
    public let userInfo: [String: any Sendable]?

    // MARK: JaysonError specific

    /// Whether the coder was encoding or decoding.
    public let process: Process

    /// The JSON text, when there was data to show.
    public let jsonText: String?

    // MARK: - Lifecycle

    // MARK: Initializer

    /// Creates a coding error.
    ///
    /// - Parameters:
    ///   - process: Whether the coder was encoding or decoding.
    ///   - summary: A short description. Defaults to a generic message for the
    ///     process.
    ///   - details: The coding path and the specific problem.
    ///   - underlyingError: The error underneath this one.
    ///   - userInfo: The coding context passed to the coder.
    ///   - data: The JSON data, kept as text for a report.
    public init(
        process: Process,
        summary: String? = nil,
        details: String? = nil,
        underlyingError: (any Error)? = nil,
        userInfo: [String: any Sendable]? = nil,
        data: Data? = nil,
    ) {

        self.summary = summary ?? (process == .encode ? "Encoding failed." : "Decoding failed.")
        self.details = details

        self.underlyingError = underlyingError
        self.userInfo = userInfo

        self.process = process
        self.jsonText =
            if let data {
                String(data: data, encoding: .utf8)
            } else {
                nil
            }
    }

    /// Turns a `DecodingError` into a `JaysonError`.
    ///
    /// Returns `nil` for a decoding error this type doesn't know how to
    /// describe.
    public static func wrap(_ error: DecodingError) -> JaysonError? {

        let details: String

        var underlyingError: (any Error)?

        switch error {
        case let .dataCorrupted(context):
            underlyingError = context.underlyingError
            details = "Data corrupted\(context.atPathString)."
        case let .keyNotFound(key, context):
            underlyingError = context.underlyingError
            details = "Missing key \"\(key.stringValue)\"\(context.atPathString)."
        case let .valueNotFound(type, context):
            underlyingError = context.underlyingError
            details = "Missing \(type)\(context.atPathString)."
        case let .typeMismatch(type, context):
            underlyingError = context.underlyingError
            details = "Expected \(type)\(context.atPathString)."
        default:
            return nil
        }

        return JaysonError(
            process: .decode,
            summary: "The data could not be read.",
            details: details,
            underlyingError: underlyingError,
        )
    }
}
