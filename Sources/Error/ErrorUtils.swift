//
// Copyright 2025 Wells Consulting.
// This file is part of Motley and is released under the MIT License.

import Foundation

public enum ErrorUtils {

    public struct Options: OptionSet, Sendable {

        public let rawValue: Int

        public init(rawValue: Int) {
            self.rawValue = rawValue
        }

        public static let details: Self = .init(rawValue: 1 << 2)
        public static let underlyingError: Self = .init(rawValue: 1 << 3)
        public static let nsError: Self = .init(rawValue: 1 << 5)

        public static let minimal: Self = []

        public static let basic: Self = [
            .details
        ]

        public static let verbose: Self = [
            .details,
            .underlyingError,
            .nsError,
        ]
    }

    public static func describe(
        _ error: any Error,
        options: Options,
        depth: Int = 0,
    ) -> String {

        var lines = [String]()

        let indent = String(repeating: "    ", count: depth)

        if let gremlin = error as? (any MotleyError) {
            if depth > 0 {
                lines.append("Underlying Error (\(type(of: error)))")
            }
            lines.append(indent + gremlin.summary)
            if options.contains(.details), let details = gremlin.details {
                lines.append(indent + details)
            }
        } else {
            if depth > 0 {
                lines.append("Underlying Error (\(type(of: error)))")
            }
            lines.append(indent + "\(error)")
        }

        if options.contains(.nsError) {
            let nsError = error as NSError
            let domain = nsError.domain
            let skipNSError =
                domain.hasPrefix("Motley")
                || (domain == "NSCocoaErrorDomain" && nsError.code == 0)

            if !skipNSError {
                var line = "Error Domain=\(domain), Code=\(nsError.code)"
                if !nsError.userInfo.isEmpty {
                    line += " \(String(describing: nsError.userInfo))"
                }
                lines.append(indent + line)
            }
        }

        if options.contains(.underlyingError),
            let underlying = (error as? (any MotleyError))?.underlyingError
        {
            lines.append(
                "\n" + Self.describe(underlying, options: options, depth: depth + 1),
            )
        }

        return lines.joined(separator: "\n")
    }
}
