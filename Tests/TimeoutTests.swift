//
// Motley – Michael's Swift Toolkit
// Copyright 2025-2026 Wells Consulting.
//

import Foundation
@testable import Motley
import Testing

struct TimeoutTests {

    private struct Boom: Error {}

    @Test func workThatFinishesInTimeComesBack() async throws {
        let value = try await Timeout.run(for: .seconds(5)) { 42 }

        #expect(value == 42)
    }

    @Test func workThatOverrunsTimesOut() async {
        await #expect(throws: TimeoutError.self) {
            try await Timeout.run(for: .milliseconds(50)) {
                try await Task.sleep(for: .seconds(5))
                return 1
            }
        }
    }

    @Test func theOperationsOwnErrorComesBack() async {
        await #expect(throws: Boom.self) {
            try await Timeout.run(for: .seconds(5)) {
                throw Boom()
            }
        }
    }

    @Test func aTimeoutSaysHowLongItWaited() async {
        var caught: TimeoutError?

        do {
            _ = try await Timeout.run(for: .milliseconds(50)) {
                try await Task.sleep(for: .seconds(5))
                return 1
            }
        } catch let error as TimeoutError {
            caught = error
        } catch {
            // Some other failure, which the test below will report.
        }

        #expect(caught?.duration == .milliseconds(50))
    }
}
