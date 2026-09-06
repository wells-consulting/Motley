//
// Motley – Michael's Swift Toolkit
// Copyright 2025-2026 Wells Consulting.
//

import Foundation

/// Parses a semantic version string like `"v0.27.1"` or `"0.27.1"`
/// into its components.
public struct SemanticVersion: Sendable, Comparable {

    public let major: Int
    public let minor: Int
    public let patch: Int

    /// Parses a version string, stripping any leading non-digit prefix (e.g. `"v"`).
    /// Returns `nil` if the string doesn't contain at least a major and minor component.
    public init?(_ string: String?) {
        guard let string else { return nil }
        let digits = string.drop(while: { !$0.isNumber })
        let parts = digits.split(separator: ".")
        guard parts.count >= 2,
            let major = Int(parts[0]),
            let minor = Int(parts[1])
        else { return nil }
        self.major = major
        self.minor = minor
        self.patch = parts.count >= 3 ? Int(parts[2]) ?? 0 : 0
    }

    public static func < (lhs: SemanticVersion, rhs: SemanticVersion) -> Bool {
        (lhs.major, lhs.minor, lhs.patch) < (rhs.major, rhs.minor, rhs.patch)
    }
}
