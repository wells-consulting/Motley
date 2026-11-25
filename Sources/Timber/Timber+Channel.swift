//
// Motley – Michael's Swift Toolkit
// Copyright 2025-2026 Wells Consulting.
//

import Foundation
import Synchronization

extension Timber {

    /// A named, independently configured persistence destination for log entries.
    ///
    /// A `Timber` instance is bound to a channel at init via
    /// `Timber(subsystem:category:channel:minimumPersistedLevel:)`. Any number
    /// of instances may share one channel; persisted entries are distinguished
    /// afterward by their call-derived `category`.
    ///
    /// A channel is app-extension safe: it depends only on `Foundation` file
    /// I/O (`FileManager`, `Data`, `URL`) and `Synchronization`, with no
    /// main-app-only imports (`UIApplication`, `NSExtensionContext`, …). It
    /// can back a log inside an app extension and be read from any process
    /// that can reach its directory, so consumers do not need a parallel
    /// storage type for extension logs.
    public actor Channel {

        // MARK: - Rotation

        /// How the channel's file makes room for new entries.
        public enum Rotation: Sendable {
            /// Renames the current file to `<name>.jsonl.1` (dropping any prior
            /// `.1`) once it reaches `thresholdBytes`, then starts a fresh file.
            /// Never rewrites the whole buffer.
            case bySize(thresholdBytes: Int)
            /// Prunes entries older than `maxAge` on load, and caps the
            /// in-memory buffer at `maxEntries`, rewriting the file whenever
            /// the cap is exceeded.
            case byCountAndAge(maxEntries: Int, maxAge: TimeInterval)
        }

        // MARK: - Properties

        /// The channel's name. It becomes the file name.
        public let name: String
        private let fileURL: URL
        private let rotatedFileURL: URL
        private let rotation: Rotation
        private let maxReadEntries: Int?
        private let jayson: Jayson
        private var buffer: [TimberLogEntry] = []
        private let generationBox = Mutex<Int>(0)

        // MARK: - Initializers

        /// Creates a channel that persists to `<name>.jsonl` in `directory`.
        ///
        /// When `maxReadEntries` is non-nil, the ``entries`` property returns at
        /// most that many entries (the most recent ones), so callers no longer
        /// need to apply `.suffix(n)` themselves.
        public init(name: String, directory: URL, rotation: Rotation, maxReadEntries: Int? = nil) {
            self.name = name
            self.rotation = rotation
            self.maxReadEntries = maxReadEntries

            let baseName = "\(name).jsonl"
            self.fileURL = directory.appendingPathComponent(baseName)
            self.rotatedFileURL = directory.appendingPathComponent("\(baseName).1")

            // Compact single-line JSON for JSONL format (no pretty printing).
            self.jayson = Jayson(
                configuration: .init(outputFormatting: [.sortedKeys, .withoutEscapingSlashes])
            )

            if case .byCountAndAge(let maxEntries, let maxAge) = rotation {
                self.buffer = Self.loadPruned(
                    from: fileURL,
                    jayson: jayson,
                    maxEntries: maxEntries,
                    maxAge: maxAge
                )
            }
        }

        // MARK: - Public API

        /// The current generation counter. Incremented by ``deleteAll()``.
        /// Used to discard entries created before a clear.
        nonisolated public var currentGeneration: Int {
            generationBox.withLock { $0 }
        }

        /// All persisted entries in chronological order (oldest first),
        /// merging the rotated file (older) with the current file (newer).
        /// Lines that fail to decode are dropped rather than throwing.
        ///
        /// When the channel was created with a non-nil `maxReadEntries`, the
        /// result is capped to the most recent `maxReadEntries` entries.
        public var entries: [TimberLogEntry] {
            let raw: [TimberLogEntry]
            switch rotation {
            case .byCountAndAge:
                raw = buffer
            case .bySize:
                raw =
                    Self.decodeEntries(at: rotatedFileURL, jayson: jayson)
                    + Self.decodeEntries(at: fileURL, jayson: jayson)
            }
            guard let cap = maxReadEntries else { return raw }
            return Array(raw.suffix(cap))
        }

        /// Appends `entry` if `generation` still matches the channel's
        /// current generation — i.e. no ``deleteAll()`` has happened since
        /// the caller captured it.
        public func append(_ entry: TimberLogEntry, generation: Int) {
            guard generation == currentGeneration else { return }
            switch rotation {
            case .bySize(let thresholdBytes):
                appendBySize(entry, thresholdBytes: thresholdBytes)
            case .byCountAndAge(let maxEntries, _):
                appendByCountAndAge(entry, maxEntries: maxEntries)
            }
        }

        /// Deletes all persisted entries and removes the backing file(s).
        public func deleteAll() throws {
            generationBox.withLock { $0 += 1 }
            buffer.removeAll()
            try TimberFileRotation.deleteAll(fileURL: fileURL, rotatedURL: rotatedFileURL)
        }

        /// Fire-and-forget append: spawns a `Task` internally and returns
        /// immediately, for callers that can't be `async`.
        nonisolated public func appendSync(_ entry: TimberLogEntry) {
            let generation = currentGeneration
            Task { await append(entry, generation: generation) }
        }

        /// Fire-and-forget delete: spawns a `Task` internally and returns
        /// immediately. `onFailure` is called (still off the calling thread)
        /// if the underlying `deleteAll()` throws; omit it to fail silently.
        nonisolated public func deleteAllSync(onFailure: (@Sendable (any Error) -> Void)? = nil) {
            Task {
                do {
                    try await deleteAll()
                } catch {
                    onFailure?(error)
                }
            }
        }

        // MARK: - bySize

        private func appendBySize(_ entry: TimberLogEntry, thresholdBytes: Int) {
            TimberFileRotation.rotateIfNeeded(
                fileURL: fileURL,
                rotatedURL: rotatedFileURL,
                thresholdBytes: thresholdBytes
            )
            guard let lineData = try? jayson.encode(entry) else { return }
            TimberFileRotation.appendLine(lineData, to: fileURL)
        }

        // MARK: - byCountAndAge

        private func appendByCountAndAge(_ entry: TimberLogEntry, maxEntries: Int) {
            buffer.append(entry)

            if buffer.count > maxEntries {
                buffer.removeFirst(buffer.count - maxEntries)
                Self.writeEntries(buffer, to: fileURL, jayson: jayson)
            } else if let lineData = try? jayson.encode(entry) {
                TimberFileRotation.appendLine(lineData, to: fileURL)
            }
        }

        // MARK: - File I/O

        private static func loadPruned(
            from fileURL: URL,
            jayson: Jayson,
            maxEntries: Int,
            maxAge: TimeInterval
        ) -> [TimberLogEntry] {
            guard FileManager.default.fileExists(atPath: fileURL.path),
                let data = try? Data(contentsOf: fileURL)
            else { return [] }

            let cutoff = Date().addingTimeInterval(-maxAge)
            let lines = data.split(separator: UInt8(ascii: "\n"))
            var entries = decodeLines(lines, jayson: jayson).filter { $0.timestamp > cutoff }

            if entries.count > maxEntries {
                entries = Array(entries.suffix(maxEntries))
            }

            if entries.count != lines.count {
                writeEntries(entries, to: fileURL, jayson: jayson)
            }

            return entries
        }

        private static func decodeEntries(at fileURL: URL, jayson: Jayson) -> [TimberLogEntry] {
            guard let data = try? Data(contentsOf: fileURL) else { return [] }
            return decodeLines(data.split(separator: UInt8(ascii: "\n")), jayson: jayson)
        }

        private static func decodeLines(_ lines: [Data], jayson: Jayson) -> [TimberLogEntry] {
            lines.compactMap { try? jayson.decode(TimberLogEntry.self, from: $0) }
        }

        private static func writeEntries(
            _ entries: [TimberLogEntry],
            to fileURL: URL,
            jayson: Jayson
        ) {
            var fileData = Data()
            for entry in entries {
                if let lineData = try? jayson.encode(entry) {
                    fileData.append(lineData)
                    fileData.append(UInt8(ascii: "\n"))
                }
            }
            try? fileData.write(to: fileURL, options: .atomic)
        }
    }
}
