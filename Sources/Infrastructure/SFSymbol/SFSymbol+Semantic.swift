//
// Motley – Michael's Swift Toolkit
// Copyright 2025-2026 Wells Consulting.
//

import Foundation

public extension SFSymbol {

    // MARK: - Status

    /// The symbol for a failure.
    static let error: Self = .exclamationmark_triangle_fill
    /// The symbol for a success.
    static let success: Self = .checkmark_circle
    /// The symbol for a warning.
    static let warning: Self = .exclamationmark_triangle

    // MARK: - Actions

    /// The symbol for canceling.
    static let cancel: Self = .xmark_circle
    /// The symbol for downloading.
    static let download: Self = .arrow_down_circle
    /// The symbol for refreshing.
    static let refresh: Self = .arrow_trianglehead_clockwise
    /// The symbol for sharing.
    static let share: Self = .arrow_up_square
}
