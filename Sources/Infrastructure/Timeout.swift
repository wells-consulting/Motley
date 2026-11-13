//
// Motley – Michael's Swift Toolkit
// Copyright 2025-2026 Wells Consulting.
//

import Foundation

/// Thrown by ``Timeout/run(for:operation:)`` when the work didn't finish in
/// time.
public struct TimeoutError: Error, LocalizedError, Sendable, Equatable {

    public let duration: Duration

    public var errorDescription: String? {
        "Timed out after \(duration)."
    }
}

/// A deadline around async work.
public enum Timeout {

    /// Runs `operation`, throwing ``TimeoutError`` if it hasn't finished in
    /// `duration`.
    ///
    /// Cancels the work when the deadline passes, so a call that would never
    /// return can't hold up the caller.
    public static func run<T: Sendable>(
        for duration: Duration,
        operation: @escaping @Sendable () async throws -> T,
    ) async throws -> T {
        try await withThrowingTaskGroup(of: T.self) { group in
            group.addTask {
                try await operation()
            }
            group.addTask {
                try await Task.sleep(for: duration)
                throw TimeoutError(duration: duration)
            }

            defer { group.cancelAll() }

            guard let result = try await group.next() else {
                throw TimeoutError(duration: duration)
            }

            return result
        }
    }
}
