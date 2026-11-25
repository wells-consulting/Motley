//
// Motley – Michael's Swift Toolkit
// Copyright 2025-2026 Wells Consulting.
//

import Foundation

/// JSON encoding and decoding with the settings the apps share.
///
/// ``shared`` is ready to use: ISO 8601 dates, pretty output with sorted keys,
/// JSON5 input and no null-escape stripping. Make another one when a call needs
/// different settings.
public struct Jayson: Sendable {

    private let encoder: JSONEncoder
    private let decoder: JSONDecoder
    private let stripNullEscapes: Bool

    private let log = Timber(formatting: [.omitSourceLocation])

    /// A coder with the default settings.
    public static let shared = Jayson()

    // MARK: - Initializers

    /// The settings for a ``Jayson``.
    public struct Configuration: Sendable {

        /// How keys are encoded. Defaults to the property names.
        public let keyEncodingStrategy: JSONEncoder.KeyEncodingStrategy

        /// How dates are encoded. Defaults to ISO 8601.
        public let dateEncodingStrategy: JSONEncoder.DateEncodingStrategy

        /// How the encoded JSON is laid out. Defaults to pretty-printed with
        /// sorted keys.
        public let outputFormatting: JSONEncoder.OutputFormatting

        /// How keys are decoded. Defaults to the property names.
        public let keyDecodingStrategy: JSONDecoder.KeyDecodingStrategy

        /// How dates are decoded. Defaults to ISO 8601.
        public let dateDecodingStrategy: JSONDecoder.DateDecodingStrategy

        /// Whether the decoder accepts JSON5. Defaults to `true`.
        public let allowsJSON5: Bool

        /// Whether `\u0000` escapes are removed before decoding. Defaults to
        /// `false`.
        public let stripNullEscapes: Bool

        /// Creates a configuration.
        ///
        /// - Parameters:
        ///   - keyEncodingStrategy: How keys are encoded.
        ///   - dateEncodingStrategy: How dates are encoded.
        ///   - outputFormatting: How the encoded JSON is laid out.
        ///   - keyDecodingStrategy: How keys are decoded.
        ///   - dateDecodingStrategy: How dates are decoded.
        ///   - allowsJSON5: Whether the decoder accepts JSON5.
        ///   - stripNullEscapes: Whether `\u0000` escapes are removed before
        ///     decoding.
        public init(
            keyEncodingStrategy: JSONEncoder.KeyEncodingStrategy = .useDefaultKeys,
            dateEncodingStrategy: JSONEncoder.DateEncodingStrategy = .iso8601,
            outputFormatting: JSONEncoder.OutputFormatting = [
                .prettyPrinted, .sortedKeys, .withoutEscapingSlashes,
            ],
            keyDecodingStrategy: JSONDecoder.KeyDecodingStrategy = .useDefaultKeys,
            dateDecodingStrategy: JSONDecoder.DateDecodingStrategy = .iso8601,
            allowsJSON5: Bool = true,
            stripNullEscapes: Bool = false,
        ) {
            self.keyEncodingStrategy = keyEncodingStrategy
            self.dateEncodingStrategy = dateEncodingStrategy
            self.outputFormatting = outputFormatting
            self.keyDecodingStrategy = keyDecodingStrategy
            self.dateDecodingStrategy = dateDecodingStrategy
            self.allowsJSON5 = allowsJSON5
            self.stripNullEscapes = stripNullEscapes
        }

        /// The default settings.
        public static let `default` = Configuration()
    }

    /// Creates a coder.
    ///
    /// - Parameter configuration: The settings to use. Defaults to
    ///   ``Configuration/default``.
    public init(configuration: Configuration = .default) {

        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = configuration.keyEncodingStrategy
        encoder.dateEncodingStrategy = configuration.dateEncodingStrategy
        encoder.outputFormatting = configuration.outputFormatting
        self.encoder = encoder

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = configuration.keyDecodingStrategy
        decoder.dateDecodingStrategy = configuration.dateDecodingStrategy
        decoder.allowsJSON5 = configuration.allowsJSON5
        self.decoder = decoder
        self.stripNullEscapes = configuration.stripNullEscapes
    }

    // MARK: - Encode

    /// Encodes a value as JSON.
    ///
    /// - Parameters:
    ///   - value: The value to encode.
    ///   - userInfo: Extra context for the encoder.
    /// - Returns: The JSON data.
    /// - Throws: ``JaysonError`` when the value can't be encoded.
    public func encode<T: Encodable>(
        _ value: T,
        userInfo: [CodingUserInfoKey: any Sendable]? = nil,
    ) throws -> Data {

        var summary = ""
        var underlyingError: (any Error)?

        do {
            if let userInfo {
                for (key, value) in userInfo {
                    encoder.userInfo[key] = value
                }
            }

            defer {
                if let userInfo {
                    for (key, _) in userInfo {
                        encoder.userInfo.removeValue(forKey: key)
                    }
                }
            }

            return try encoder.encode(value)
        } catch let EncodingError.invalidValue(key, context) {
            underlyingError = context.underlyingError
            summary =
                "Failed to encode \(T.self): key \"\(key)\" is missing\(context.atPathString)."
        } catch {
            underlyingError = error
            summary = "Failed to encode \(T.self)."
        }

        let errorUserInfo: [String: any Sendable]? =
            if let userInfo {
                Dictionary(uniqueKeysWithValues: userInfo.map { ($0.key.rawValue, $0.value) })
            } else {
                nil
            }

        throw JaysonError(
            process: .encode,
            summary: summary,
            underlyingError: underlyingError,
            userInfo: errorUserInfo
        )
    }

    // MARK: - Decode

    /// Decodes a value from JSON data.
    ///
    /// - Parameters:
    ///   - type: The type to decode.
    ///   - data: The JSON data. `nil` throws.
    ///   - userInfo: Extra context for the decoder.
    /// - Returns: The decoded value.
    /// - Throws: ``JaysonError`` when the data is missing or can't be decoded.
    public func decode<T: Decodable>(
        _ type: T.Type,
        from data: Data?,
        userInfo: [CodingUserInfoKey: any Sendable]? = nil,
    ) throws -> T {

        guard let data else {
            let message = "Failed to decode \(T.self): no data."
            log.error(message)
            throw JaysonError(process: .decode, summary: message)
        }

        let decodableData: Data
        if stripNullEscapes,
            let str = String(data: data, encoding: .utf8),
            str.contains("\\u0000")
        {
            decodableData =
                str
                .replacingOccurrences(of: "\\u0000", with: "")
                .data(using: .utf8) ?? data
        } else {
            decodableData = data
        }

        var summary: String
        var underlyingError: (any Error)?

        do {
            if let userInfo {
                for (key, value) in userInfo {
                    decoder.userInfo[key] = value
                }
            }

            defer {
                if let userInfo {
                    for (key, _) in userInfo {
                        decoder.userInfo.removeValue(forKey: key)
                    }
                }
            }

            let object: T = try decoder.decode(T.self, from: decodableData)

            return object
        } catch let DecodingError.dataCorrupted(context) {
            underlyingError = context.underlyingError
            summary = "Failed to decode \(T.self): data corrupted\(context.atPathString)."
        } catch let DecodingError.keyNotFound(key, context) {
            underlyingError = context.underlyingError
            summary =
                "Failed to decode \(T.self): missing key \"\(key.stringValue)\"\(context.atPathString)."
        } catch let DecodingError.valueNotFound(type, context) {
            underlyingError = context.underlyingError
            summary = "Failed to decode \(T.self): missing \(type)\(context.atPathString)."
        } catch let DecodingError.typeMismatch(type, context) {
            underlyingError = context.underlyingError
            summary = "Failed to decode \(T.self): expected \(type)\(context.atPathString)."
        } catch {
            underlyingError = error
            summary = "Failed to decode \(T.self)."
        }

        let errorUserInfo: [String: any Sendable]? =
            if let userInfo {
                Dictionary(uniqueKeysWithValues: userInfo.map { ($0.key.rawValue, $0.value) })
            } else {
                nil
            }

        throw JaysonError(
            process: .decode,
            summary: summary,
            underlyingError: underlyingError,
            userInfo: errorUserInfo,
            data: decodableData,
        )
    }

    // MARK: - Decode from String

    /// Decodes a value from a JSON string.
    ///
    /// - Parameters:
    ///   - type: The type to decode.
    ///   - string: The JSON text.
    ///   - userInfo: Extra context for the decoder.
    /// - Returns: The decoded value.
    /// - Throws: ``JaysonError`` when the text can't be decoded.
    public func decode<T: Decodable>(
        _ type: T.Type,
        from string: String,
        userInfo: [CodingUserInfoKey: any Sendable]? = nil,
    ) throws -> T {
        try decode(type, from: string.data(using: .utf8), userInfo: userInfo)
    }

    // MARK: - Encode to String

    /// Encodes a value as a JSON string.
    ///
    /// - Parameters:
    ///   - value: The value to encode.
    ///   - userInfo: Extra context for the encoder.
    /// - Returns: The JSON text.
    /// - Throws: ``JaysonError`` when the value can't be encoded.
    public func string<T: Encodable>(
        from value: T,
        userInfo: [CodingUserInfoKey: any Sendable]? = nil,
    ) throws -> String {

        let data = try encode(value, userInfo: userInfo)

        guard let string = String(data: data, encoding: .utf8) else {
            throw JaysonError(
                process: .encode,
                summary: "Failed to encode \(T.self) to a UTF-8 string.",
            )
        }

        return string
    }

    // MARK: - Stringify

    /// Encodes a value as a JSON string, or returns `nil` when it fails.
    ///
    /// For the throwing version, use ``string(from:userInfo:)``.
    ///
    /// - Parameter value: The value to encode.
    /// - Returns: The JSON text, or `nil`.
    public func stringify(_ value: some Encodable) -> String? {
        do {
            let data = try encoder.encode(value)
            return String(data: data, encoding: .utf8)
        } catch {
            return nil
        }
    }
}

// MARK: - Private Extensions

extension EncodingError.Context {

    var atPathString: String {

        let path =
            codingPath
            .filter { !$0.stringValue.isEmpty }
            .map(\.stringValue)
            .joined(separator: ".")

        if path.isEmpty {
            return ""
        } else {
            return " at \"\(path)\""
        }
    }
}

extension DecodingError.Context {

    var atPathString: String {

        let path =
            codingPath
            .filter { !$0.stringValue.isEmpty }
            .map(\.stringValue)
            .joined(separator: ".")

        if path.isEmpty {
            return ""
        } else {
            return " at \"\(path)\""
        }
    }
}
