//
// Motley – Michael's Swift Toolkit
// Copyright 2025-2026 Wells Consulting.
//

import Foundation
@testable import Motley
import Testing

struct CalendarExtensionTests {

    @Test func gregorianIsGregorianInTheGivenZone() throws {
        let zone = try #require(TimeZone(identifier: "Pacific/Auckland"))
        let calendar = Calendar.gregorian(in: zone)

        #expect(calendar.identifier == .gregorian)
        #expect(calendar.timeZone == zone)
    }

    @Test func gregorianKeepsTheDevicesFirstWeekday() {
        let zone = TimeZone(identifier: "America/Los_Angeles") ?? .gmt

        #expect(Calendar.gregorian(in: zone).locale == .current)
    }

    @Test func monthBoundariesFollowTheZoneNotTheDevice() throws {
        let zone = try #require(TimeZone(identifier: "America/Los_Angeles"))
        let calendar = Calendar.gregorian(in: zone)
        let date = try #require(
            calendar.date(from: DateComponents(year: 2026, month: 3, day: 15, hour: 12)),
        )
        let month = try #require(calendar.dateInterval(of: .month, for: date))

        #expect(calendar.component(.day, from: month.start) == 1)
        #expect(calendar.component(.month, from: month.start) == 3)
        #expect(calendar.component(.hour, from: month.start) == 0)
    }

    @Test func utcIsGregorianInUTC() {
        let calendar = Calendar.gregorianUTC

        #expect(calendar.identifier == .gregorian)
        #expect(calendar.timeZone == .gmt)
    }

    @Test func utcDayStartsAtMidnightUTC() throws {
        let date = try #require(
            Calendar.gregorianUTC.date(from: DateComponents(year: 2026, month: 3, day: 15, hour: 18)),
        )
        let day = try #require(Calendar.gregorianUTC.dateInterval(of: .day, for: date))

        #expect(Calendar.gregorianUTC.component(.hour, from: day.start) == 0)
        #expect(Calendar.gregorianUTC.component(.day, from: day.start) == 15)
    }
}
