//
// Motley – Michael's Swift Toolkit
// Copyright 2025-2026 Wells Consulting.
//

import Foundation
import os

/// A `Timber` instance may be bound to a ``Channel`` at init to persist
/// entries at or above `minimumPersistedLevel` to disk. Any number of
/// instances may share one channel.
///
/// The persisted `category` of each entry is **call-derived**: by default it
/// is the file the logging call site lives in (from `#fileID`), unless
/// overridden with an explicit `category:` on the logging call. The
/// `category:` given at init is a separate, coarser facet that only
/// labels the `os.Logger` `(subsystem, category)` pair and is never written
/// to the channel.

public struct Timber: Sendable {

    // MARK: - Formatting

    public struct Formatting: OptionSet, Sendable {
        public let rawValue: Int
        public static let omitSourceLocation = Formatting(rawValue: 1 << 0)
        public static let decorateSourceLocation = Formatting(rawValue: 1 << 1)
        public static let omitFunction = Formatting(rawValue: 1 << 2)
        public static let omitFile = Formatting(rawValue: 1 << 3)
        public static let omitParameterLabels = Formatting(rawValue: 1 << 4)
        public static let omitLine = Formatting(rawValue: 1 << 5)
        public init(rawValue: Int) {
            self.rawValue = rawValue
        }
    }

    // MARK: - Properties

    let subsystem: String
    let formatting: Formatting?
    let channel: Channel?
    let minimumPersistedLevel: TimberLogLevel
    private let logger: os.Logger

    // MARK: - Initializers

    /// Creates a logger scoped to the given subsystem and category.
    /// - Parameters:
    ///   - subsystem: Reverse-DNS bundle identifier for the subsystem
    ///     (e.g. `"com.example.MyApp"`). Defaults to `"consulting.wells.Motley"`.
    ///   - category: A coarse, static label for `os.Logger` grouping (e.g.
    ///     `"network"`, `"ui"`). Defaults to `#fileID`. Independent from the
    ///     per-entry, call-derived `category:` on each logging call.
    ///   - formatting: What each line includes. Defaults to `nil`, which uses
    ///     the source location and parameter labels.
    ///   - channel: A ``Channel`` to persist entries to. Defaults to `nil`
    ///     (no persistence — messages still reach `os.Logger`).
    ///   - minimumPersistedLevel: Only entries at or above this level are
    ///     persisted to `channel`. Defaults to `.error`.
    public init(
        subsystem: String = "consulting.wells.Motley",
        category: String = #fileID,
        formatting: Formatting? = nil,
        channel: Channel? = nil,
        minimumPersistedLevel: TimberLogLevel = .error
    ) {
        self.subsystem = subsystem
        self.formatting = formatting
        self.channel = channel
        self.minimumPersistedLevel = minimumPersistedLevel
        self.logger = os.Logger(subsystem: subsystem, category: category)
    }

    // MARK: - Persistence

    /// Persists `message` to `channel` if bound and `level` is at or above
    /// `minimumPersistedLevel`. Fires off the actual write asynchronously so
    /// logging calls remain synchronous.
    private func persist(
        level: TimberLogLevel,
        message: String,
        category: String?,
        file: String,
        function: String,
        line: UInt
    ) {
        guard let channel, level >= minimumPersistedLevel else { return }
        let entry = TimberLogEntry(
            id: UUID(),
            timestamp: Date(),
            level: level,
            subsystem: subsystem,
            category: category ?? Self.defaultCategory(from: file),
            message: message,
            file: file,
            function: function,
            line: line
        )
        let generation = channel.currentGeneration
        Task {
            await channel.append(entry, generation: generation)
        }
    }

    // MARK: - Logging

    /// Logs a message at the **debug** level.
    public func debug(
        _ message: String,
        formatting: Formatting? = nil,
        file: String = #fileID,
        function: String = #function,
        line: UInt = #line,
        category: String? = nil,
    ) {
        let formatted = formatMessage(
            message,
            formatting: formatting ?? self.formatting,
            file: file,
            function: function,
            line: line
        )
        logger.debug("\(formatted)")
        persist(
            level: .debug,
            message: message,
            category: category,
            file: file,
            function: function,
            line: line
        )
    }

    /// Logs a message at the **info** level.
    public func info(
        _ message: String,
        formatting: Formatting? = nil,
        file: String = #fileID,
        function: String = #function,
        line: UInt = #line,
        category: String? = nil,
    ) {
        let formatted = formatMessage(
            message,
            formatting: formatting ?? self.formatting,
            file: file,
            function: function,
            line: line
        )
        logger.info("\(formatted)")
        persist(
            level: .info,
            message: message,
            category: category,
            file: file,
            function: function,
            line: line
        )
    }

    /// Logs a message at the **notice** level.
    public func notice(
        _ message: String,
        formatting: Formatting? = nil,
        file: String = #fileID,
        function: String = #function,
        line: UInt = #line,
        category: String? = nil,
    ) {
        let formatted = formatMessage(
            message,
            formatting: formatting ?? self.formatting,
            file: file,
            function: function,
            line: line
        )
        logger.notice("\(formatted)")
        persist(
            level: .notice,
            message: message,
            category: category,
            file: file,
            function: function,
            line: line
        )
    }

    /// Logs a message at the **error** level.
    public func error(
        _ message: String,
        formatting: Formatting? = nil,
        file: String = #fileID,
        function: String = #function,
        line: UInt = #line,
        category: String? = nil,
    ) {
        let formatted = formatMessage(
            message,
            formatting: formatting ?? self.formatting,
            file: file,
            function: function,
            line: line
        )
        logger.error("\(formatted)")
        persist(
            level: .error,
            message: message,
            category: category,
            file: file,
            function: function,
            line: line
        )
    }

    // MARK: - Convenience

    /// Logs a task-failure message at the **error** level.
    ///
    /// When `task` is non-nil the message is formatted as
    /// `"\(task) failed with error: \(message)"`; otherwise `message` is
    /// passed through unchanged.
    public func error(
        _ message: String,
        while task: String?,
        formatting: Formatting? = nil,
        file: String = #fileID,
        function: String = #function,
        line: UInt = #line,
        category: String? = nil,
    ) {
        let taskMessage = task.map { "\($0) failed with error: \(message)" } ?? message
        let formatted = formatMessage(
            taskMessage,
            formatting: formatting ?? self.formatting,
            file: file,
            function: function,
            line: line
        )
        logger.error("\(formatted)")
        persist(
            level: .error,
            message: taskMessage,
            category: category,
            file: file,
            function: function,
            line: line
        )
    }

    /// Logs an `Error` value at the **error** level, optionally prefixed with a task name.
    public func error(
        _ error: any Error,
        while task: String? = nil,
        formatting: Formatting? = nil,
        file: String = #fileID,
        function: String = #function,
        line: UInt = #line,
        category: String? = nil,
    ) {
        let errorMessage = task.map { "\($0) failed with error: \(error)" } ?? "\(error)"
        let formatted = formatMessage(
            errorMessage,
            formatting: formatting ?? self.formatting,
            file: file,
            function: function,
            line: line
        )
        logger.error("\(formatted)")
        persist(
            level: .error,
            message: errorMessage,
            category: category,
            file: file,
            function: function,
            line: line
        )
    }
}

// MARK: - Helpers

extension Timber {

    /// Reduces a `#fileID` string to the persisted `category` for entries
    /// logged without an explicit `category:`.
    ///
    /// Steps applied in order:
    /// 1. Strip the module prefix and slash
    ///    `"MyApp/Networking/APIClient.swift"` → `"Networking/APIClient.swift"`
    /// 2. Strip the file extension
    ///    `"Networking/APIClient.swift"` → `"Networking/APIClient"`
    public static func defaultCategory(from file: String) -> String {
        var name = file
        if let slash = name.firstIndex(of: "/") {
            name = String(name[name.index(after: slash)...])
        }
        if let dot = name.lastIndex(of: ".") {
            name = String(name[..<dot])
        }
        return name
    }

    /// Reduces a `#fileID` string to the shortest useful label for log output.
    ///
    /// Steps applied in order:
    /// 1. Strip the module prefix and slash
    ///     `"MyApp/Labrador.swift"` → `"Labrador.swift"`
    /// 2. Strip the file extension
    ///     `"Labrador.swift"` → `"Labrador"`
    /// 3. Strip everything up to and including the last `+`, if present
    ///    `"Some+Scene"` → `"Scene"`, `"SomeViewModel"` → `"SomeViewModel"`
    public static func shortFile(_ fileID: String) -> String {
        var name = fileID
        if let slash = name.lastIndex(of: "/") {
            name = String(name[name.index(after: slash)...])
        }
        if let dot = name.lastIndex(of: ".") {
            name = String(name[..<dot])
        }
        if let plus = name.lastIndex(of: "+") {
            name = String(name[name.index(after: plus)...])
        }
        return name
    }

    func formatMessage(
        _ message: String,
        formatting: Formatting?,
        file: String,
        function: String,
        line: UInt
    ) -> String {
        guard
            let effectiveFormatting = formatting ?? self.formatting,
            !effectiveFormatting.isEmpty,
            !effectiveFormatting.contains(.omitSourceLocation)
        else { return message }
        var location = String()
        location.reserveCapacity(64)
        if !effectiveFormatting.contains(.omitFile) {
            location.append(Self.shortFile(file))
        }
        if !effectiveFormatting.contains(.omitFunction), !function.isEmpty {
            if !location.isEmpty { location.append(":") }
            if effectiveFormatting.contains(.omitParameterLabels) {
                location.append(function.functionBaseName)
            } else {
                location.append(function)
            }
        }
        if !effectiveFormatting.contains(.omitLine) {
            if !location.isEmpty { location.append(":") }
            location.append("\(line)")
        }
        guard !location.isEmpty else { return message }
        if effectiveFormatting.contains(.decorateSourceLocation) {
            return "\(message) [\(location)]"
        }
        return "\(message) \(location)"
    }
}
