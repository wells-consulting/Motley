//
// Motley – Michael's Swift Toolkit
// Copyright 2025-2026 Wells Consulting.
//

import Foundation

/// A rotating plain-text line store for forensic/audit-style logging.
///
/// This coexists with ``Timber/Channel`` rather than being folded into it
/// because it is a different shape: entries are opaque, caller-formatted
/// strings — never structured `TimberLogEntry` JSON — and they are never
/// routed through `os.Logger`/console, so security-sensitive logging produces
/// no console noise and no recursion risk.
///
/// The two storage types share the same rotation code: rotate if over budget,
/// append a newline-delimited line, read back, delete all. Size-based rotation
/// behaves the same in both. They differ only in what they write and where the
/// logs are routed.
public actor TimberLineStore {

    // MARK: - Properties

    private let fileURL: URL
    private let rotatedFileURL: URL
    private let thresholdBytes: Int

    // MARK: - Initializers

    /// Creates a store that persists to `fileName` in `directory`, rotating
    /// to `<fileName>.1` once the current file reaches `thresholdBytes`.
    public init(directory: URL, fileName: String, thresholdBytes: Int) {
        self.fileURL = directory.appendingPathComponent(fileName)
        self.rotatedFileURL = directory.appendingPathComponent("\(fileName).1")
        self.thresholdBytes = thresholdBytes
    }

    // MARK: - Public API

    /// Appends `line` to the current file, rotating first if the current
    /// file has reached `thresholdBytes`.
    public func append(_ line: String) {
        TimberFileRotation.rotateIfNeeded(
            fileURL: fileURL,
            rotatedURL: rotatedFileURL,
            thresholdBytes: thresholdBytes
        )
        guard let data = line.data(using: .utf8) else { return }
        TimberFileRotation.appendLine(data, to: fileURL)
    }

    /// All lines from the rotated file (older) followed by the current file
    /// (newer), in the order they were written.
    public var lines: [String] {
        (TimberFileRotation.readLines(at: rotatedFileURL)
            + TimberFileRotation.readLines(at: fileURL))
            .compactMap { String(data: $0, encoding: .utf8) }
    }

    /// Deletes all persisted lines and removes the backing file(s).
    public func deleteAll() throws {
        try TimberFileRotation.deleteAll(fileURL: fileURL, rotatedURL: rotatedFileURL)
    }
}
