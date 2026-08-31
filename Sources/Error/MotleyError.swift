//
// Copyright 2025-2026 Wells Consulting.
// This file is part of Motley and is released under the MIT License.
//

import Foundation

/// Common protocol for errors thrown by Motley modules.

public protocol MotleyError: Error, LocalizedError, CustomStringConvertible, Sendable {

    // Required, user-facing

    /// A concise description of what went wrong. Maps to
    /// LocalizedError.errorDescription.
    var summary: String { get }

    // Optional, user-facing

    /// Detailed reasoning for the error that would help a tech-savvy
    /// user. It may, for example, include the HTTP status code.
    /// Maps to LocalizedError.failureReason.
    var details: String? { get }

    // Optional, developer-facing

    /// The originating error, if this error wraps another.
    var underlyingError: (any Error)? { get }

    /// Classifies this error so consumers can determine appropriate
    /// recovery behavior (e.g. retry, prompt user, fix configuration).
    var kind: ErrorKind { get }
}

// MARK: - Default Implementations

extension MotleyError {

    /// Concise human-readable description for string interpolation.
    public var description: String {
        summary
    }

    /// Default LocalizedError
    public var errorDescription: String? {
        summary
    }

    /// Default LocalizedError
    public var failureReason: String? {
        details
    }

    public var details: String? { nil }
    public var underlyingError: (any Error)? { nil }
    public var kind: ErrorKind { .persistent }

    /// Produce a human-readable diagnostic string for this error.
    public func diagnostics(options: ErrorUtils.Options) -> String? {
        ErrorUtils.describe(self, options: options)
    }
}
