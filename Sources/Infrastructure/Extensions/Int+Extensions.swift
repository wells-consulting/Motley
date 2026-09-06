//
// Motley – Michael's Swift Toolkit
// Copyright 2025-2026 Wells Consulting.
//

import Foundation

public extension Int {

    // MARK: - String Conversion

    func string(
        grouping: NumberFormatStyleConfiguration.Grouping = .automatic,
    ) -> String {
        formatted(.number.grouping(grouping))
    }

    /// Returns e.g. "1 scene" or "5 scenes".
    /// Handles English consonant+y → ies (gallery → galleries, entry → entries).
    /// NOTE: Useful, but for localized strings, use the string catalog instead.
    func pluralized(_ singular: String) -> String {
        if self == 1 { return "1 \(singular)" }
        if singular.hasSuffix("y"),
            let beforeY = singular.dropLast().last,
            !"aeiou".contains(beforeY)
        {
            return "\(formatted()) \(String(singular.dropLast()))ies"
        }
        return "\(formatted()) \(singular)s"
    }
}
