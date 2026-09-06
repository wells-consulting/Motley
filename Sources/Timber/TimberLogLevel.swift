//
// Motley – Michael's Swift Toolkit
// Copyright 2025-2026 Wells Consulting.
//

import Foundation

public enum TimberLogLevel: String, Comparable, Codable, Sendable {

    case debug
    case info
    case notice
    case error

    private var severity: Int {
        switch self {
        case .debug: 0
        case .info: 1
        case .notice: 2
        case .error: 3
        }
    }

    public static func < (lhs: Self, rhs: Self) -> Bool {
        lhs.severity < rhs.severity
    }
}
