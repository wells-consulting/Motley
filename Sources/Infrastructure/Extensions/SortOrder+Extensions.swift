//
// Motley – Michael's Swift Toolkit
// Copyright 2025-2026 Wells Consulting.
//

import Foundation

public extension SortOrder {

    static var ascending: SortOrder { .forward }
    static var descending: SortOrder { .reverse }

    mutating func toggle() {
        switch self {
        case .forward:
            self = .reverse
        case .reverse:
            self = .forward
        }
    }
}
