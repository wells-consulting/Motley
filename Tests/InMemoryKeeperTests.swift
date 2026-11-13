//
// Motley – Michael's Swift Toolkit
// Copyright 2025-2026 Wells Consulting.
//

import Foundation
@testable import Motley
import Testing

/// Both stores answer the same way, so an app can swap one for the other.
struct InMemoryKeeperTests {

    private struct Credentials: Codable, Equatable {
        var token: String
        var expires: Int
    }

    private let keeper = InMemoryKeeper()

    @Test func aSavedValueComesBack() throws {
        let credentials = Credentials(token: "abc", expires: 42)

        try keeper.save(credentials, forKey: "signin")

        #expect(try keeper.load(Credentials.self, forKey: "signin") == credentials)
    }

    @Test func savingReplacesTheValue() throws {
        try keeper.save("first", forKey: "token")
        try keeper.save("second", forKey: "token")

        #expect(try keeper.load(String.self, forKey: "token") == "second")
    }

    @Test func aKeyThatIsNotThereIsNotFound() {
        #expect(!keeper.exists(key: "missing"))

        #expect(throws: KeeperError.self) {
            try keeper.load(String.self, forKey: "missing")
        }
    }

    @Test func existsFollowsTheKeys() throws {
        try keeper.save("value", forKey: "token")
        #expect(keeper.exists(key: "token"))

        try keeper.delete(key: "token")
        #expect(!keeper.exists(key: "token"))
    }

    @Test func deletingAKeyThatIsNotThereIsFine() throws {
        try keeper.delete(key: "missing")

        #expect(!keeper.exists(key: "missing"))
    }

    @Test func eachStoreHasItsOwnValues() throws {
        let other = InMemoryKeeper()
        try keeper.save("mine", forKey: "token")

        #expect(!other.exists(key: "token"))
    }
}
