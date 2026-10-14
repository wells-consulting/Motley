//
// Motley – Michael's Swift Toolkit
// Copyright 2025-2026 Wells Consulting.
//

import Foundation

/// A structured notice with summary text, optional details, and a tone
/// that indicates how it should be presented to the user.
public struct Message: Hashable, Codable, Sendable {

    // MARK: - Properties

    /// Localized notice text
    public let summary: String

    /// Additional details
    public var details: String?

    /// Title; typically used in UI for dialogs or alerts
    public var title: String?

    /// Notice kind; typically used to style text in UI
    public let kind: Kind

    // MARK: - Initializer

    init(summary: String, details: String? = nil, title: String? = nil, kind: Kind) {
        self.summary = summary
        self.details = details
        self.title = title
        self.kind = kind
    }

    // MARK: - Factory Methods

    /// Creates a text notice.
    ///
    /// - Parameters:
    ///     - summary: Notice text
    ///     - details: Verbose and possibly debug text
    ///     - title: Title
    ///
    /// - Returns:
    ///     Informational notice
    public static func text(
        _ summary: String,
        details: String? = nil,
        title: String? = nil,
    ) -> Self {
        .init(summary: summary, details: details, title: title, kind: .text)
    }

    /// Creates an informational notice.
    ///
    /// - Parameters:
    ///     - summary: Notice text
    ///     - details: Verbose and possibly debug text
    ///     - title: Notice title
    ///
    /// - Returns:
    ///     Informational notice
    public static func info(
        _ summary: String,
        details: String? = nil,
        title: String? = nil,
    ) -> Self {
        .init(summary: summary, details: details, title: title, kind: .info)
    }

    /// Creates a warning notice.
    ///
    /// - Parameters:
    ///     - summary: Notice text
    ///     - details: Verbose and possibly debug text
    ///     - title: Notice title
    ///
    /// - Returns:
    ///     Warning notice
    public static func notice(
        _ summary: String,
        details: String? = nil,
        title: String? = nil,
    ) -> Self {
        .init(summary: summary, details: details, title: title, kind: .notice)
    }

    /// Creates an error notice.
    ///
    /// - Parameters:
    ///     - summary: Notice text
    ///     - details: Verbose and possibly debug text
    ///     - title: Notice title
    ///
    /// - Returns:
    ///     Error notice
    public static func error(
        _ summary: String,
        details: String? = nil,
        title: String? = nil,
    ) -> Self {
        .init(summary: summary, details: details, title: title, kind: .error)
    }

    /// Creates an error notice from any `Error`.
    ///
    /// Title is inferred as follows: if title is supplied at call site, that
    /// title is used. If the title is not supplied and the error has a title,
    /// that title is used. Otherwise, the notice is created without a title.
    ///
    /// - Parameters:
    ///     - error: Any error
    ///     - details: Verbose and possibly debug text
    ///     - title: Notice title
    ///
    /// - Returns:
    ///     Error notice
    public static func error(
        _ error: any Error,
        details: String? = nil,
        title: String? = nil,
    ) -> Self {
        .init(
            summary: error.localizedDescription,
            details: details ?? (error as? any LocalizedError)?.failureReason,
            title: title,
            kind: .error
        )
    }

    /// Notice kind
    public enum Kind: Int, Equatable, Comparable, Codable, Sendable {

        case text
        case info
        case notice
        case error

        public var title: String {
            switch self {
            case .text:
                "Text"
            case .info:
                "Info"
            case .notice:
                "Notice"
            case .error:
                "Error"
            }
        }

        public var symbol: SFSymbol? {
            switch self {
            case .text:
                .bubble
            case .info:
                .info_circle
            case .notice:
                .exclamationmark_circle
            case .error:
                .exclamationmark_triangle_fill
            }
        }

        public static func < (lhs: Self, rhs: Self) -> Bool {
            lhs.rawValue < rhs.rawValue
        }
    }
}
