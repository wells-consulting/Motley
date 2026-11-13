//
// Motley – Michael's Swift Toolkit
// Copyright 2025-2026 Wells Consulting.
//

import Foundation
@testable import Motley
import Testing

struct RateLimiterTests {

    // MARK: - Helpers

    /// Runs `count` `acquire()` calls at once and returns when each one got
    /// through, in order. When `acquire` returns is what's measured, not when
    /// the task started, so a task that waited shows the bucket's spacing.
    private static func grantTimes(
        _ limiter: RateLimiter,
        count: Int
    ) async throws -> [TimeInterval] {
        try await withThrowingTaskGroup(of: TimeInterval.self) { group in
            for _ in 0..<count {
                group.addTask {
                    try await limiter.acquire()
                    return ProcessInfo.processInfo.systemUptime
                }
            }

            var result: [TimeInterval] = []
            for try await granted in group {
                result.append(granted)
            }
            return result.sorted()
        }
    }

    // MARK: - Pacing

    @Test func sustainedRateNeverPacesFasterThanRefill() async throws {
        // 20 requests a second with a burst of 5. Grants 0 to 4 are the burst
        // and can bunch up, but grant n can't happen before (n - burst) / rate
        // has passed. A wake that's late is handed back as tokens, so only a
        // minimum on the total is safe from jitter.
        let burst = 5
        let rate = 20.0
        let limiter = RateLimiter(requests: Int(rate), per: 1, burst: burst)
        let starts = try await Self.grantTimes(limiter, count: 20)

        let minimumTotal = Double(20 - burst - 1) * (1.0 / rate)
        #expect(starts.last! - starts.first! >= minimumTotal - 0.05)
    }

    @Test func drainedBucketWaitsOutRefill() async throws {
        // 5 requests a second, burst of 1. Three grants can't all happen inside
        // the refill window, since grant n needs (n - 1) / rate to pass.
        let rate = 5.0
        let limiter = RateLimiter(requests: Int(rate), per: 1, burst: 1)
        let starts = try await Self.grantTimes(limiter, count: 3)

        let minimumTotal = 2 * (1.0 / rate)
        #expect(starts.last! - starts.first! >= minimumTotal - 0.05)
    }

    @Test func burstAllowsBoundedFanOutImmediately() async throws {
        // Up to `burst` grants go through without waiting. The first refill
        // token isn't due until 0.6s here, so finishing well before that shows
        // the burst worked.
        let limiter = RateLimiter(requests: 100, per: 60, burst: 3)
        let starts = try await Self.grantTimes(limiter, count: 3)

        #expect(starts.last! - starts.first! < 0.5)
    }

    @Test func limitersAreIndependent() async throws {
        let paced = RateLimiter(requests: 1, per: 0.2, burst: 1)
        let free = RateLimiter(requests: 1000, per: 60, burst: 1000)

        try await paced.acquire()  // drain `paced`'s only token

        // While `paced` has to wait about 0.2s, `free` still goes through. One
        // caller's limiter shouldn't slow down another's.
        async let pacedNext: Void = paced.acquire()
        async let freeNow: Void = free.acquire()

        let start = ProcessInfo.processInfo.systemUptime
        try await freeNow
        let freeWait = ProcessInfo.processInfo.systemUptime - start
        _ = try await pacedNext
        let pacedWait = ProcessInfo.processInfo.systemUptime - start

        #expect(freeWait < pacedWait)
    }

    // MARK: - Manual clock

    @Test func aDrainedBucketGrantsOnePerRefill() async throws {
        // No waiting: the clock jumps to each deadline, so the grants land on
        // exact intervals once the burst is spent.
        let clock = ManualClock()
        let limiter = RateLimiter(requests: 20, per: 1, burst: 5, clock: clock)

        var grantedAt: [Duration] = []
        for _ in 0..<8 {
            try await limiter.acquire()
            grantedAt.append(clock.now.elapsed)
        }

        #expect(grantedAt[0..<5] == ArraySlice(repeating: Duration.zero, count: 5))

        for (index, milliseconds) in [(5, 50), (6, 100), (7, 150)] {
            let drift = grantedAt[index] - .milliseconds(milliseconds)
            #expect(drift > .milliseconds(-1) && drift < .milliseconds(1))
        }
    }

    @Test func aBurstWaitsForTheBucketToRefill() async throws {
        // 1 request a second with a burst of 2: two go straight through, then
        // each one costs a whole second.
        let clock = ManualClock()
        let limiter = RateLimiter(requests: 1, per: 1, burst: 2, clock: clock)

        try await limiter.acquire()
        try await limiter.acquire()
        let afterBurst = clock.now.elapsed

        try await limiter.acquire()
        let wait = clock.now.elapsed - afterBurst

        #expect(afterBurst == .zero)
        #expect(wait > .milliseconds(999) && wait < .milliseconds(1_001))
    }
}
