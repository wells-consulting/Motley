//
// Motley – Michael's Swift Toolkit
// Copyright 2025-2026 Wells Consulting.
//

import Foundation

public struct JaysonError: MotleyError {

    public enum Process: Sendable {
        case encode
        case decode
    }

    // MARK: - Properties

    public let summary: String
    public let details: String?
    public let underlyingError: (any Error)?
    public let userInfo: [String: any Sendable]?

    // MARK: JaysonError specific

    public let process: Process
    public let jsonText: String?

    // MARK: - Lifecycle

    // MARK: Initializer

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
