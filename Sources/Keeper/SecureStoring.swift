//
// Motley – Michael's Swift Toolkit
// Copyright 2025-2026 Wells Consulting.
//

import Foundation

/// A secure key-value store, so an app can take the keychain in production and
/// a dictionary in previews and tests.
public protocol SecureStoring: Sendable {

    /// Whether anything is stored under `key`.
    func exists(key: String) -> Bool

    /// The value under `key`.
    ///
    /// - Throws: `KeeperError.itemNotFound` when there's nothing there.
    func load<T: Codable>(_ type: T.Type, forKey key: String) throws -> T

    func save(_ value: some Codable, forKey key: String) throws

    func delete(key: String) throws
}
