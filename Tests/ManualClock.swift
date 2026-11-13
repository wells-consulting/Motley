//
// Motley – Michael's Swift Toolkit
// Copyright 2025-2026 Wells Consulting.
//

import Foundation
import Synchronization

/// A clock that only moves when something waits on it.
///
/// `sleep(until:)` returns at once and moves the clock to the deadline, so a
/// test can assert pacing without spending the time.
final class ManualClock: Clock, Sendable {

    struct Instant: InstantProtocol, Sendable {

        let elapsed: Duration

        func advanced(by duration: Duration) -> Instant {
            Instant(elapsed: elapsed + duration)
        }

        func duration(to other: Instant) -> Duration {
            other.elapsed - elapsed
        }

        static func < (lhs: Instant, rhs: Instant) -> Bool {
            lhs.elapsed < rhs.elapsed
        }
    }

    private let elapsed = Mutex<Duration>(.zero)

    var now: Instant {
        Instant(elapsed: elapsed.withLock { $0 })
    }

    var minimumResolution: Duration {
        .zero
    }

    func sleep(until deadline: Instant, tolerance: Duration? = nil) async throws {
        elapsed.withLock { $0 = max($0, deadline.elapsed) }
    }
}
