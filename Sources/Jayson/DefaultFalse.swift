//
// Motley – Michael's Swift Toolkit
// Copyright 2025-2026 Wells Consulting.
//

import Foundation

/// A flag the JSON only writes when it's true, so a missing key means `false`
/// and the property doesn't have to be optional.
///
/// ```swift
/// @DefaultFalse var verified: Bool   // {} decodes to false
/// ```
@propertyWrapper
public struct DefaultFalse: Codable, Hashable, Sendable {

    public var wrappedValue: Bool

    public init(wrappedValue: Bool = false) {
        self.wrappedValue = wrappedValue
    }

    public init(from decoder: any Decoder) throws {
        wrappedValue = try decoder.singleValueContainer().decode(Bool.self)
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(wrappedValue)
    }
}

public extension KeyedDecodingContainer {

    /// A missing key decodes as `false`.
    func decode(_ type: DefaultFalse.Type, forKey key: Key) throws -> DefaultFalse {
        try decodeIfPresent(type, forKey: key) ?? DefaultFalse()
    }
}
