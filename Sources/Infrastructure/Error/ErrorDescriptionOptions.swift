//
// Motley – Michael's Swift Toolkit
// Copyright 2025-2026 Wells Consulting.
//

import Foundation

public struct ErrorDescriptionOptions: OptionSet, Sendable {

    public let rawValue: Int
    public init(rawValue: Int) {
        self.rawValue = rawValue
    }

    public static let details: Self = .init(rawValue: 1 << 2)
    public static let underlyingError: Self = .init(rawValue: 1 << 3)
    public static let nsError: Self = .init(rawValue: 1 << 5)
    public static let minimal: Self = []
    public static let basic: Self = [ .details]
    public static let verbose: Self = [
        .details,
        .underlyingError,
        .nsError,
    ]
}
