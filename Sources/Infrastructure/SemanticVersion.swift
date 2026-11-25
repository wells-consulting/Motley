//
// Motley – Michael's Swift Toolkit
// Copyright 2025-2026 Wells Consulting.
//

import Foundation

/// A version with major, minor and patch numbers.
///
/// ```swift
/// let version = SemanticVersion("v1.2.3")
/// version?.major   // 1
/// version?.minor   // 2
/// version?.patch   // 3
/// ```
public struct SemanticVersion: Sendable, Comparable {

    /// The major version.
    public let major: Int

    /// The minor version.
    public let minor: Int

    /// The patch version. Defaults to zero when the string leaves it out.
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
