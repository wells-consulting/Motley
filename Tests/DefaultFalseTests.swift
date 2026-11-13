//
// Motley – Michael's Swift Toolkit
// Copyright 2025-2026 Wells Consulting.
//

import Foundation
@testable import Motley
import Testing

struct DefaultFalseTests {

    private struct Flag: Codable, Equatable {
        var name: String
        @DefaultFalse var verified: Bool
    }

    @Test func aMissingKeyDecodesAsFalse() throws {
        let json = Data(#"{"name":"reading"}"#.utf8)
        let flag = try Jayson.shared.decode(Flag.self, from: json)

        #expect(flag.verified == false)
    }

    @Test func aPresentKeyDecodesAsWritten() throws {
        let json = Data(#"{"name":"reading","verified":true}"#.utf8)
        let flag = try Jayson.shared.decode(Flag.self, from: json)

        #expect(flag.verified)
    }

    @Test func encodingWritesTheValue() throws {
        let data = try Jayson.shared.encode(Flag(name: "reading"))

        // Decoded without the wrapper, so the key has to be there on its own.
        let plain = try JSONDecoder().decode(PlainFlag.self, from: data)

        #expect(plain.verified == false)
        #expect(try Jayson.shared.decode(Flag.self, from: data) == Flag(name: "reading"))
    }

    private struct PlainFlag: Decodable {
        var verified: Bool
    }
}
