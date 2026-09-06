//
// Motley – Michael's Swift Toolkit
// Copyright 2025-2026 Wells Consulting.
//

import Foundation

public struct KeeperError: MotleyError {

    // MARK: - Properties

    public let summary: String
    public let details: String?
    public let underlyingError: (any Error)?

    // MARK: KeychainError specific

    /// The `OSStatus` returned by the Security framework, if applicable.
    public let status: OSStatus?

    // MARK: - Lifecycle

    // MARK: Initializer

    init(
        summary: String,
        details: String? = nil,
        underlyingError: (any Error)? = nil,
        status: OSStatus? = nil,
    ) {
        self.summary = summary
        self.details = details
        self.underlyingError = underlyingError
        self.status = status
    }

    // MARK: Factory Methods

    static func itemNotFound(key: String) -> KeeperError {
        KeeperError(
            summary: "Item not found.",
            details: "Key: \(key).",
            status: errSecItemNotFound,
        )
    }

    static func saveFailed(key: String, status: OSStatus) -> KeeperError {
        KeeperError(
            summary: "Unable to save to the keychain.",
            details: "Key: \(key), OSStatus: \(status).",
            status: status,
        )
    }

    static func loadFailed(key: String, status: OSStatus) -> KeeperError {
        KeeperError(
            summary: "Unable to load from the keychain.",
            details: "Key: \(key), OSStatus: \(status).",
            status: status,
        )
    }

    static func deleteFailed(key: String, status: OSStatus) -> KeeperError {
        KeeperError(
            summary: "Unable to delete from the keychain.",
            details: "Key: \(key), OSStatus: \(status).",
            status: status,
        )
    }

    static func encodingFailed(key: String, underlyingError: any Error) -> KeeperError {
        KeeperError(
            summary: "Unable to save to the keychain.",
            details: "Key: \(key). Encoding failed.",
            underlyingError: underlyingError,
        )
    }

    static func decodingFailed(key: String, underlyingError: any Error) -> KeeperError {
        KeeperError(
            summary: "Unable to load from the keychain.",
            details: "Key: \(key). Decoding failed.",
            underlyingError: underlyingError,
        )
    }
}
