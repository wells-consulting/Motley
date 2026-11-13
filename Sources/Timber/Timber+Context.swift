//
// Motley – Michael's Swift Toolkit
// Copyright 2025-2026 Wells Consulting.
//

import Foundation

public extension Timber {

    /// A label that goes with the task, so a line in the log traces back to
    /// whatever caused it: `"[settings] loadAccount"`.
    ///
    /// A fan-out root sets it once with ``withValue(_:detail:operation:)``, and
    /// every call under it — through `async let`, task groups and actor hops —
    /// logs with the same prefix. It reaches structured concurrency and
    /// `Task {}`; only `Task.detached` starts without it.
    ///
    /// ```swift
    /// await Timber.Context.withValue("settings") {
    ///     try await account.load()   // logs "[settings] load"
    /// }
    /// ```
    enum Context {

        /// How much a scope logs.
        public enum Detail: Sendable {

            /// Every call. For interactive work making a handful.
            case everyCall

            /// Only the scope's own start and finish lines. For a batch job
            /// making hundreds of calls, where one line each is noise.
            case summaryOnly
        }

        /// The active label, or `nil` outside a scope.
        @TaskLocal
        public static var current: String?

        /// What the scope logs. Set with ``withValue(_:detail:operation:)``,
        /// and it goes with the task like ``current``.
        @TaskLocal
        public static var detail: Detail = .everyCall

        /// Runs `operation` with `value` as the active label.
        ///
        /// `detail` defaults to `.everyCall`; pass `.summaryOnly` for a batch
        /// job, which stops ``logCall(_:_:file:function:line:)`` for the whole
        /// scope.
        ///
        /// The closure stays on the caller's actor, so it can call back into
        /// whatever started the work.
        nonisolated(nonsending)
        public static func withValue<T>(
            _ value: String,
            detail: Detail = .everyCall,
            operation: () async throws -> T,
        ) async rethrows -> T {
            try await $current.withValue(value) {
                try await $detail.withValue(detail) {
                    try await operation()
                }
            }
        }

        /// Runs `operation` with `purpose` added to the active label, so a call
        /// says why it fired and not just where it came from:
        /// `"[energy > forecast-warmup] dailyForecast"`. Keeps the enclosing
        /// scope's ``detail``.
        nonisolated(nonsending)
        public static func withPurpose<T>(
            _ purpose: String,
            operation: () async throws -> T,
        ) async rethrows -> T {
            let value = current.map { "\($0) > \(purpose)" } ?? purpose
            return try await withValue(value, detail: detail, operation: operation)
        }

        /// `"[label] baseName"` when there's a label, otherwise `"baseName"`.
        ///
        /// `function` defaults to the caller's `#function`.
        public static func label(function: String = #function) -> String {
            let base = function.functionBaseName

            guard let current else {
                return base
            }

            return "[\(current)] \(base)"
        }

        /// Logs through `log` with the label first:
        /// `"[settings] loadAccount | account=42"`.
        ///
        /// Does nothing in a `.summaryOnly` scope, where the job's own start and
        /// finish lines are the record. `file`, `function` and `line` are passed
        /// through, so the log records the caller and not this wrapper.
        public static func logCall(
            _ log: Timber,
            _ details: String? = nil,
            file: String = #fileID,
            function: String = #function,
            line: UInt = #line,
        ) {
            guard detail == .everyCall else {
                return
            }

            guard let details, !details.isEmpty else {
                log.debug(label(function: function), file: file, function: function, line: line)
                return
            }

            log.debug(
                "\(label(function: function)) | \(details)",
                file: file,
                function: function,
                line: line
            )
        }
    }
}
