//
// Motley – Michael's Swift Toolkit
// Copyright 2025-2026 Wells Consulting.
//

import Foundation

/// All Errors thrown by Motely conforms to this protocol. The only
/// required property is summary. All the others have reasonable
/// defaults.
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

// MARK: Back-fill

public extension Error {

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
}
