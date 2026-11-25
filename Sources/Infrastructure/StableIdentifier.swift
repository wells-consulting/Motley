//
// Motley – Michael's Swift Toolkit
// Copyright 2025-2026 Wells Consulting.
//

import Foundation

/// Generates and persists a stable, pronounceable two-word phrase.
///
/// The phrase is derived from a random seed stored in the Keychain under the
/// given seed key. Two instances sharing the same seed key resolve to the same
/// phrase across launches, which is intended for correlating diagnostics
/// reports — not as a device identifier.
public struct StableIdentifier: Sendable {

    /// Stable two-word phrase for this seed, e.g. `"amber_harbor"`.
    ///
    /// Resolved once at init from a Keychain-persisted seed. The seed is
    /// generated on first access and saved; later launches load the saved
    /// value. If the Keychain is unavailable, the phrase is new on each
    /// launch.
    public let phrase: String

    /// Creates a stable identifier backed by the Keychain.
    ///
    /// - Parameter seedKey: Keychain key that persists the seed. Defaults to a
    ///   package-wide key shared by all callers; pass a distinct key to scope
    ///   identifiers to a single feature.
    public init(seedKey: String? = nil) {
        let keeper = Keeper()
        let key = seedKey ?? Self.defaultSeedKey
        let seed = Self.loadOrCreateSeed(with: keeper, forKey: key)
        let adjective = WordList.adjectives[Int((seed >> 32) % UInt64(WordList.adjectives.count))]
        let noun = WordList.nouns[Int((seed & 0xFFFF_FFFF) % UInt64(WordList.nouns.count))]
        phrase = "\(adjective)_\(noun)"
    }

    /// Builds a filename prefixed with this identifier.
    ///
    /// - Parameters:
    ///   - prefix: Feature-specific prefix, e.g. "backup".
    ///   - ext: Optional file extension.
    public func filename(
        prefix: String,
        ext: String? = nil
    ) -> String {
        let timestamp = Date.now.safeTimestamp
        var filename = "\(phrase)_\(prefix)_\(timestamp)"
        if let ext { filename += ".\(ext)" }
        return filename
    }

    // MARK: - Private

    private static let defaultSeedKey = "motley.stableid.seed"

    private static func loadOrCreateSeed(with keeper: Keeper, forKey key: String) -> UInt64 {
        // swiftlint:disable no_try_question
        if let seed = try? keeper.load(UInt64.self, forKey: key) {
            return seed
        }
        let seed = UInt64.random(in: .min ... .max)
        try? keeper.save(seed, forKey: key)
        // swiftlint:enable no_try_question
        return seed
    }
}
