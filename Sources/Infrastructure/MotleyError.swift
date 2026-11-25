//
// Motley – Michael's Swift Toolkit
// Copyright 2025-2026 Wells Consulting.
//

import Foundation

/// Errors thrown by Motley conform to this protocol.
///
/// Only ``summary`` is required. The rest have defaults, so an error type can
/// start with a message and add detail where it helps.
public protocol MotleyError: LocalizedError {
    var summary: String { get }
    var details: String? { get }
    var underlyingError: (any Error)? { get }
    var errorKind: ErrorKind { get }
}

// MARK: Default Implementation

public extension MotleyError {
    var details: String? { nil }
    var underlyingError: (any Error)? { nil }
    var errorKind: ErrorKind { .unclassified }
}

// MARK: - ErrorKind

/// A rough guess at whether retrying the same call can help.
public enum ErrorKind: String, Sendable {

    /// Transient failures that may succeed on retry (network timeout, temporary
    /// server error, rate limiting).
    case transient

    /// Persistent failures where retrying the same operation won't help without
    /// user intervention (bad credentials, missing resource, permission denied).
    case persistent

    /// Configuration errors where the user needs to change a setting before
    /// retrying (invalid URL, missing host, bad port).
    case configuration

    /// Errors that have not been classified or have no natural classification.
    case unclassified
}
