//
// Motley – Michael's Swift Toolkit
// Copyright 2025-2026 Wells Consulting.
//

import Foundation

/// The landscape vocabulary behind diagnostics names and settings-file codes.
///
/// `StableIdentifier` takes one adjective and one noun from these lists, and
/// a four-word transfer code takes two of each. Keeping them here means both
/// read as the same thing rather than two different generators.
public enum WordList {

    // MARK: - Words

    public static let adjectives: [String] = [
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

    public static let nouns: [String] = [
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

    // MARK: - Codes

    /// `words` words, taken in turn from the adjective and noun lists. An odd
    /// count ends on an adjective; zero or less returns an empty string.
    public static func randomCode(words: Int) -> String {
        guard words > 0 else { return "" }

        var picked: [String] = []
        for index in 0..<words {
            let list = index.isMultiple(of: 2) ? adjectives : nouns
            picked.append(list[Int.random(in: 0..<list.count)])
        }
        return picked.joined(separator: " ")
    }
}
