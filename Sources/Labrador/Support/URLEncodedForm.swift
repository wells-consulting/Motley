//
// Motley – Michael's Swift Toolkit
// Copyright 2025-2026 Wells Consulting.
//

import Foundation

/// Builds an `application/x-www-form-urlencoded` body.
public final class URLEncodedForm: SummaryProviding {

    private var parameters: [String: String] = [:]

    /// Whether the form has no fields.
    public var isEmpty: Bool { parameters.isEmpty }

    /// A log-friendly summary of the fields.
    public var summary: String {
        parameters.map { "\($0.key)=\($0.value)" }.joined(separator: "&")
    }

    /// Creates an empty form.
    public init() {}

    /// The encoded body.
    public var data: Data {
        var components = URLComponents()
        components.queryItems = parameters.map {
            URLQueryItem(name: "\($0.key)", value: "\($0.value)")
        }
        return Data((components.percentEncodedQuery ?? "").utf8)
    }

    /// Adds a field, replacing any value already under the same name.
    public func addingField(name: String, value: String) -> Self {
        parameters[name] = value
        return self
    }
}
