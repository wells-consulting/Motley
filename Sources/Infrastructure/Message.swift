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
    ///   - summary: The notice text.
    ///   - details: The longer text, when there is more to say.
    ///   - title: The title to show above the summary.
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
    ///   - summary: The notice text.
    ///   - details: The longer text, when there is more to say.
    ///   - title: The title to show above the summary.
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
    ///   - summary: The notice text.
    ///   - details: The longer text, when there is more to say.
    ///   - title: The title to show above the summary.
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
    ///   - summary: The notice text.
    ///   - details: The longer text, when there is more to say.
    ///   - title: The title to show above the summary.
    public static func error(
        _ summary: String,
        details: String? = nil,
        title: String? = nil,
    ) -> Self {
        .init(summary: summary, details: details, title: title, kind: .error)
    }

    /// Creates an error notice from any error.
    ///
    /// The title comes from the call site when you pass one. Otherwise it comes
    /// from the error when the error has a title, and the notice has no title
    /// when it doesn't.
    ///
    /// - Parameters:
    ///   - error: The error to describe.
    ///   - details: The longer text, when there is more to say.
    ///   - title: The title to show above the summary.
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

        /// The display title for the kind.
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

        /// The symbol that goes with the kind.
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
