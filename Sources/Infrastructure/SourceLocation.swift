//
// Motley – Michael's Swift Toolkit
// Copyright 2025-2026 Wells Consulting.
//

import Foundation

/// A file, function and line, captured at a call site.
public struct SourceLocation: Sendable, CustomStringConvertible {

    /// The file ID, like `"Motley/Timber.swift"`.
    public let file: String

    /// The function name.
    public let function: String

    /// The line number.
    public let line: UInt

    /// Creates a location from its pieces.
    public init(file: String, function: String, line: UInt) {
        self.file = file
        self.function = function
        self.line = line
    }

    /// The caller's location.
    public static func current(
        file: String = #fileID,
        function: String = #function,
        line: UInt = #line
    ) -> Self {
        .init(file: file, function: function, line: line)
    }

    /// `file:function:line`.
    public var description: String {
        "\(file):\(function):\(line)"
    }
}
