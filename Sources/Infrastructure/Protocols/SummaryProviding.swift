//
// Motley – Michael's Swift Toolkit
// Copyright 2025-2026 Wells Consulting.
//

import Foundation

/// Types providing summary text.
///
/// ```swift
///
/// let lotsOfData = try await URLSession.shared.data(for: urlRequest)
///
/// print(lotsOfData.summary)
/// ```
///     25.8 GB
///
public protocol SummaryProviding {
    var summary: String { get }
}
