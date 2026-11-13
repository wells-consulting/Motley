//
// Motley – Michael's Swift Toolkit
// Copyright 2025-2026 Wells Consulting.
//

import Foundation
@testable import Motley
import Testing

/// The derived ids are stored in rows and used as CloudKit record names, so a
/// change to the algorithm would leave one row behind per device. These are the
/// outputs from the app's implementation before the move.
struct UUIDExtensionTests {

    private static let pinned: [(key: String, id: String)] = [
        ("a", "ca978112-ca1b-5dca-bac2-31b39a23dc4d"),
        ("monthly-chunk", "a81358b6-0379-5770-b777-fa3ef46946c4"),
        (
            "daily_fact_chunks/7e2cd707-3e31-41c7-89b0-7adb8c341736/2026-03",
            "44283663-63ae-5862-8e99-98fafdf4fe7c"
        ),
        (
            "grid_history_chunks/11e2c0a4-9e0a-4a12-8b7f-3f4a1c2d5e6f/2026-03",
            "a92d0ac7-12bd-5375-9301-b01fdf9e0490"
        ),
        (
            "weather_history_chunks/37.33,-122.03/.temperatureHigh/2026-03",
            "a60c390f-0116-583f-b89a-6fecfb55a709"
        ),
        (
            "feed_history_chunks/3f2b1c8e-6a4d-4e5f-9a7b-1c2d3e4f5a6b/interval/.production/2026-03",
            "039b7e0e-e6ea-5ee9-be80-a770888d441b"
        ),
        (
            "feed_history_chunks/3f2b1c8e-6a4d-4e5f-9a7b-1c2d3e4f5a6b/interval/.production/2026-04",
            "a341f482-5e0f-56f3-9636-da1813997f4b"
        ),
    ]

    @Test func derivedIDsAreTheOnesAlreadyStored() {
        for pin in Self.pinned {
            #expect(UUID(derivedFrom: pin.key).lowercasedString == pin.id, "key: \(pin.key)")
        }
    }

    @Test func derivedIDsAreVersionFive() {
        for pin in Self.pinned {
            let text = UUID(derivedFrom: pin.key).lowercasedString
            let characters = Array(text)

            #expect(characters[14] == "5")
            #expect("89ab".contains(characters[19]))
        }
    }

    @Test func aNewIDIsLowercaseAndParses() throws {
        let id = UUID.newLowercasedString()

        #expect(id == id.lowercased())
        #expect(UUID(uuidString: id) != nil)
    }

    @Test func oneUUIDHasOneSpelling() throws {
        let uuid = try #require(UUID(uuidString: "ABCDEF00-1234-5678-9ABC-DEF012345678"))

        #expect(uuid.lowercasedString == "abcdef00-1234-5678-9abc-def012345678")
    }
}
