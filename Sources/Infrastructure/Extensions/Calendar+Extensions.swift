//
// Motley – Michael's Swift Toolkit
// Copyright 2025-2026 Wells Consulting.
//

import Foundation

public extension Calendar {

    /// The calendar to cut a data source's days, months and years on: Gregorian
    /// in `timeZone`, so a device set to another calendar system (Buddhist,
    /// Hebrew, …) can't move where a period starts and ends.
    ///
    /// The locale stays the device's, since it only decides which weekday a
    /// week starts on.
    static func gregorian(in timeZone: TimeZone) -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = .current
        calendar.timeZone = timeZone
        return calendar
    }

    /// Gregorian in UTC, for math on days that have no time zone.
    static let gregorianUTC: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .gmt
        return calendar
    }()
}
