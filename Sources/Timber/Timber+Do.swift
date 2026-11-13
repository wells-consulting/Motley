//
// Motley – Michael's Swift Toolkit
// Copyright 2025-2026 Wells Consulting.
//

import Foundation

public extension Timber {

    /// Runs `operation`, logging anything it throws.
    ///
    /// Cancellation is a request to stop, not a failure, so it's skipped.
    func `do`(
        _ task: String,
        file: String = #fileID,
        function: String = #function,
        line: UInt = #line,
        _ operation: () throws -> Void,
    ) {
        do {
            try operation()
        } catch is CancellationError {
            // Cancellation is a request to stop, not a failure to report.
        } catch {
            self.error(error, while: task, file: file, function: function, line: line)
        }
    }

    /// Runs `operation`, logging anything it throws and returning `nil`.
    func `do`<T>(
        _ task: String,
        file: String = #fileID,
        function: String = #function,
        line: UInt = #line,
        _ operation: () throws -> T?,
    ) -> T? {
        do {
            return try operation()
        } catch is CancellationError {
            return nil
        } catch {
            self.error(error, while: task, file: file, function: function, line: line)
            return nil
        }
    }

    /// The async form that returns nothing.
    nonisolated(nonsending)
    func `do`(
        _ task: String,
        file: String = #fileID,
        function: String = #function,
        line: UInt = #line,
        _ operation: () async throws -> Void,
    ) async {
        do {
            try await operation()
        } catch is CancellationError {
            // Cancellation is a request to stop, not a failure to report.
        } catch {
            self.error(error, while: task, file: file, function: function, line: line)
        }
    }

    /// The async form that returns a value.
    nonisolated(nonsending)
    func `do`<T>(
        _ task: String,
        file: String = #fileID,
        function: String = #function,
        line: UInt = #line,
        _ operation: () async throws -> T?,
    ) async -> T? {
        do {
            return try await operation()
        } catch is CancellationError {
            return nil
        } catch {
            self.error(error, while: task, file: file, function: function, line: line)
            return nil
        }
    }
}
