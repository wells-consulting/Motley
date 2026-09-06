//
// Motley – Michael's Swift Toolkit
// Copyright 2025-2026 Wells Consulting.
//

import Foundation

public extension Error {

    func describe(
        options: ErrorDescriptionOptions,
        depth: Int = 0,
    ) -> String {

        var lines = [String]()

        let indent = String(repeating: "    ", count: depth)

        if let error = self as? (any MotleyError) {
            if depth > 0 {
                lines.append("Underlying Error (\(type(of: self)))")
            }
            lines.append(indent + error.summary)
            if options.contains(.details), let details = error.details {
                lines.append(indent + details)
            }
        } else {
            if depth > 0 {
                lines.append("Underlying Error (\(type(of: self)))")
            }
            lines.append(indent + "\(self)")
        }

        if options.contains(.nsError) {
            let nsError = self as NSError
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
            let ule = (self as? (any MotleyError))?.underlyingError
        {
            lines.append(
                "\n" + ule.describe(options: options, depth: depth + 1)
            )
        }

        return lines.joined(separator: "\n")
    }
}
