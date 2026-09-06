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

    /// Stable two-word phrase for this seed, e.g. "amber-harbor".
    ///
    /// Resolved once at init from a Keychain-persisted seed. The seed is
    /// generated on first access and saved; subsequent launches load the
    /// saved value. Returns "unknown" only if the Keychain is completely
    /// unavailable.
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
        let adjective = Self.adjectives[Int((seed >> 32) % UInt64(Self.adjectives.count))]
        let noun = Self.nouns[Int((seed & 0xFFFF_FFFF) % UInt64(Self.nouns.count))]
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

    // MARK: - Word Lists

    private static let adjectives: [String] = [
        "airy", "amber", "ancient", "arctic", "ashen",
        "autumn", "azure", "birch", "bleak", "bold",
        "breezy", "bright", "brisk", "broad", "briny",
        "bronze", "calm", "cedar", "chalk", "chill",
        "clear", "cobalt", "cold", "cool", "coral",
        "crisp", "crystal", "cloudy", "copper", "dark",
        "dawn", "deep", "dense", "dewy", "distant",
        "dusky", "dusty", "damp", "dune", "early",
        "eastern", "elder", "ember", "emerald", "even",
        "fair", "fern", "fierce", "fixed", "fleet",
        "flat", "foggy", "fresh", "frosted", "gentle",
        "glacial", "glad", "glint", "gold", "golden",
        "grand", "granite", "green", "grey", "hardy",
        "hazy", "hazel", "heath", "hidden", "high",
        "hollow", "icy", "idle", "indigo", "inland",
        "iron", "jade", "keen", "lavender", "leafy",
        "lean", "larch", "lofty", "long", "low",
        "lunar", "maple", "mellow", "mild", "mint",
        "misty", "moody", "mossy", "muted", "narrow",
        "night", "noble", "north", "oaken", "ochre",
        "olive", "open", "outer", "pale", "peach",
        "pine", "plain", "polar", "prime", "pure",
        "quiet", "rainy", "rapid", "raven", "raw",
        "real", "remote", "ridge", "rime", "roan",
        "rocky", "rosy", "royal", "rugged", "rush",
        "russet", "rustic", "sage", "salt", "sandy",
        "serene", "shaded", "shale", "sheer", "silver",
        "slim", "slow", "snowy", "solar", "spare",
        "stark", "steel", "stern", "still", "stone",
        "stormy", "strand", "sunlit", "sunny", "swift",
        "tall", "tawny", "teal", "thorn", "timber",
        "tranquil", "true", "tundra", "twilight", "upper",
        "vivid", "warm", "west", "wide", "wild",
        "wiry", "wispy", "worn", "worthy",
    ]

    private static let nouns: [String] = [
        "bank", "basin", "bay", "beacon", "bend",
        "bluff", "bloom", "bolt", "branch", "brook",
        "burrow", "butte", "camp", "canyon", "cape",
        "chain", "channel", "chasm", "cleft", "cliff",
        "coast", "cove", "crag", "creek", "crest",
        "crown", "dale", "delta", "draw", "drift",
        "drop", "dune", "echo", "edge", "falls",
        "fault", "fen", "ferry", "field", "firth",
        "fjord", "flats", "flame", "flint", "flow",
        "foam", "fog", "ford", "forest", "fork",
        "frost", "gate", "glade", "glen", "gorge",
        "grain", "grove", "gulf", "gully", "gust",
        "harbor", "haven", "heath", "hill", "hollow",
        "horn", "hull", "hurst", "ice", "inlet",
        "iron", "isle", "keep", "kelp", "key",
        "knoll", "lagoon", "lake", "ledge", "light",
        "loch", "loop", "manor", "marsh", "mast",
        "meadow", "mesa", "mire", "moon", "moor",
        "moss", "mount", "mouth", "narrows", "neck",
        "notch", "pass", "peak", "plains", "plateau",
        "pond", "pool", "port", "range", "ravine",
        "reef", "ridge", "river", "rock", "root",
        "run", "rush", "rune", "salt", "shard",
        "shelf", "shell", "shore", "silt", "sky",
        "slate", "slough", "sod", "sound", "spire",
        "spring", "spur", "strand", "stream", "summit",
        "sun", "swale", "tarn", "tide", "timber",
        "tor", "trace", "trail", "vale", "valley",
        "ward", "warden", "watch", "water", "wave",
        "weir", "wilds", "wood",
    ]
}
