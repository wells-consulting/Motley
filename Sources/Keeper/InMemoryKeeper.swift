//
// Motley – Michael's Swift Toolkit
// Copyright 2025-2026 Wells Consulting.
//

import Foundation
import Synchronization

/// A `SecureStoring` that keeps everything in memory, for previews and tests.
///
/// It throws the same `KeeperError` cases as ``Keeper``, so code that catches
/// one catches the other.
public final class InMemoryKeeper: SecureStoring {

    private let storage = Mutex<[String: Data]>([:])

    public init() {}

    // MARK: - SecureStoring

    public func exists(key: String) -> Bool {
        storage.withLock { $0[key] != nil }
    }

    public func load<T: Codable>(_ type: T.Type, forKey key: String) throws -> T {
        guard let data = storage.withLock({ $0[key] }) else {
            throw KeeperError.itemNotFound(key: key)
        }

        do {
            return try Jayson.shared.decode(T.self, from: data)
        } catch {
            throw KeeperError.decodingFailed(key: key, underlyingError: error)
        }
    }

    public func save(_ value: some Codable, forKey key: String) throws {
        do {
            let data = try Jayson.shared.encode(value)
            storage.withLock { $0[key] = data }
        } catch {
            throw KeeperError.encodingFailed(key: key, underlyingError: error)
        }
    }

    public func delete(key: String) throws {
        _ = storage.withLock { $0.removeValue(forKey: key) }
    }
}
