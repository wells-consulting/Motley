//
// Copyright 2025-2026 Wells Consulting.
// This file is part of Motley and is released under the MIT License.
//

import Foundation

public struct CaseyError: MotleyError {

    // MARK: - Properties

    public let summary: String
    public let details: String?
    public let underlyingError: (any Error)?

    // MARK: - Lifecycle

    // MARK: Initializers

    init(
        summary: String? = nil,
        details: String? = nil,
        underlyingError: (any Error)? = nil,
    ) {
        self.summary = summary ?? "Failed to save file."
        self.details = details
        self.underlyingError = underlyingError
    }

    // MARK: Factory Methods

    static func saveTo(
        _ url: URL,
        data: Data,
        error: any Error,
    ) -> Self {

        .init(
            summary: "Failed to save file.",
            details: "\(data.count.formatted(.byteCount(style: .file))) to \"\(url.lastPathComponent)\".",
            underlyingError: error,
        )
    }

    static func saveToDownloadsFolder(
        filename: String,
        data: Data,
        error: any Error,
    ) -> Self {

        .init(
            summary: "Failed to save \"\(filename)\" to Downloads.",
            details: "\(data.count.formatted(.byteCount(style: .file))).",
            underlyingError: error,
        )
    }
}
