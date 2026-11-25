//
// Motley – Michael's Swift Toolkit
// Copyright 2025-2026 Wells Consulting.
//

import Foundation

/// How serious a log line is.
public enum TimberLogLevel: String, Comparable, Codable, Sendable {

    /// Detail for development.
    case debug
    /// Something happened that may be useful later.
    case info
    /// Something unusual, but not a failure.
    case notice
    /// A failure.
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
