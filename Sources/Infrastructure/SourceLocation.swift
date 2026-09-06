//
// Motley – Michael's Swift Toolkit
// Copyright 2025-2026 Wells Consulting.
//

import Foundation

public struct SourceLocation: Sendable, CustomStringConvertible {

    public let file: String
    public let function: String
    public let line: UInt

    public init(file: String, function: String, line: UInt) {
        self.file = file
        self.function = function
        self.line = line
    }

    public static func current(
        file: String = #fileID,
        function: String = #function,
        line: UInt = #line
    ) -> Self {
        .init(file: file, function: function, line: line)
    }

    public var description: String {
        "\(file):\(function):\(line)"
    }
}
