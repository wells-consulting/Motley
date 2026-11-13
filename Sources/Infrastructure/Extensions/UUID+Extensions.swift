//
// Motley – Michael's Swift Toolkit
// Copyright 2025-2026 Wells Consulting.
//

import CryptoKit
import Foundation

public extension UUID {

    /// The UUID as lowercase text, the form rows are stored and named with.
    ///
    /// SQLite compares TEXT with case, and CloudKit record names are lowercase,
    /// so one column held in two cases stops matching on another device.
    var lowercasedString: String {
        uuidString.lowercased()
    }

    /// A new UUID as lowercase text.
    static func newLowercasedString() -> String {
        UUID().lowercasedString
    }

    /// The same UUID on every device for the same `key`: a SHA-256 of it, shaped
    /// like a version 5 UUID.
    ///
    /// For rows two devices might both write, so they end up as one record
    /// instead of two.
    init(derivedFrom key: String) {
        var bytes = Array(SHA256.hash(data: Data(key.utf8)).prefix(16))

        // Version 5, then the RFC 4122 variant, so the result parses as a UUID.
        bytes[6] = (bytes[6] & 0x0F) | 0x50
        bytes[8] = (bytes[8] & 0x3F) | 0x80

        self = UUID(
            uuid: (
                bytes[0], bytes[1], bytes[2], bytes[3], bytes[4], bytes[5], bytes[6], bytes[7],
                bytes[8], bytes[9], bytes[10], bytes[11], bytes[12], bytes[13], bytes[14], bytes[15]
            )
        )
    }
}
