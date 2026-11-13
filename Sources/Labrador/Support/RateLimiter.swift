//
// Motley – Michael's Swift Toolkit
// Copyright 2025-2026 Wells Consulting.
//

import Foundation

/// A token bucket that paces outgoing requests.
///
/// The bucket starts full with `burst` tokens and earns `requests` more every
/// `per` seconds. Callers go through back to back until it's empty, then each
/// `acquire()` waits for the next token.
///
/// Canceling a task that's waiting in `acquire()` doesn't spend its token.
public actor RateLimiter {

    // MARK: - Properties

    /// Tokens the bucket earns every `per` seconds.
    public let requests: Int

    /// The window `requests` is measured over, in seconds.
    public let per: TimeInterval

    /// Tokens the bucket holds, and how many requests can go out back to back.
    public let burst: Int

    private let timeline: Timeline
    private var tokens: Double
    private var lastRefill: Duration?

    /// Tokens per second.
    private var refillRate: Double {
        Double(requests) / per
    }

    // MARK: - Initializer

    /// Creates a limiter.
    ///
    /// - Parameters:
    ///   - requests: Tokens earned every `per` seconds.
    ///   - per: The window, in seconds. Defaults to a minute.
    ///   - burst: Tokens the bucket holds. Defaults to one, so requests are
    ///     evenly spaced.
    ///   - clock: What the limiter paces against. Tests pass a manual clock so
    ///     they don't have to wait.
    public init(
        requests: Int,
        per: TimeInterval = 60,
        burst: Int = 1,
        clock: some Clock<Duration> = ContinuousClock(),
    ) {
        precondition(requests > 0 && burst > 0 && per > 0)
        self.requests = requests
        self.per = per
        self.burst = burst
        self.tokens = Double(burst)

        // Only elapsed time matters, so the clock is reduced to two closures
        // and its instant type stays out of the actor.
        let epoch = clock.now
        self.timeline = Timeline(
            now: { epoch.duration(to: clock.now) },
            sleep: { try await clock.sleep(for: $0) },
        )
    }

    // MARK: - Acquire

    /// Takes one token, waiting for the next one when the bucket is empty.
    ///
    /// - Throws: `CancellationError` if the task is canceled while it waits.
    public func acquire() async throws {
        // Several waiters can wake at once, so check again in a loop. The check
        // doesn't suspend, so only one of them gets each token.
        while true {
            earnTokens()

            if tokens >= 1 {
                tokens -= 1
                return
            }

            let wait = Duration.seconds((1.0 - tokens) / refillRate)
            try await timeline.sleep(wait)
        }
    }

    // MARK: - Private

    /// Adds what the bucket earned since the last refill, up to `burst`.
    private func earnTokens() {
        let now = timeline.now()

        if let lastRefill {
            let elapsed = (now - lastRefill) / Duration.seconds(1)
            tokens = min(Double(burst), tokens + elapsed * refillRate)
        }

        lastRefill = now
    }

    /// Elapsed time and waiting, without the clock's instant type.
    private struct Timeline: Sendable {

        let now: @Sendable () -> Duration

        let sleep: @Sendable (Duration) async throws -> Void
    }
}
