//
// Motley – Michael's Swift Toolkit
// Copyright 2025-2026 Wells Consulting.
//

import Foundation

/// Decodes an element from a JSON array, silently discarding entries that
/// fail to decode so one corrupt entry doesn't poison the entire collection.
public struct SafeDecodable<T: Decodable>: Decodable {

    /// The decoded value, or `nil` when the entry failed.
    public let value: T?

    public init(from decoder: any Decoder) throws {
        self.value = try? T(from: decoder)  // swiftlint:disable:this no_try_question
    }
}
