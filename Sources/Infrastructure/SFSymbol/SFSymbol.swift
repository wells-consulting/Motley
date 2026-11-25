//
// Motley – Michael's Swift Toolkit
// Copyright 2025-2026 Wells Consulting.
//

import Foundation

/// A type-safe wrapper around an SF Symbol name.
public struct SFSymbol: RawRepresentable, Sendable, Hashable {

    /// The SF Symbol name, like `"gear"`.
    public let rawValue: String

    /// Creates a symbol from its name.
    public init(rawValue: String) {
        self.rawValue = rawValue
    }
}

// Custom Codable to persist as if it were an enum.
extension SFSymbol: Codable {

    public init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        rawValue = try container.decode(String.self)
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue)
    }
}
