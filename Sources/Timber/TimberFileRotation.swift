//
// Motley – Michael's Swift Toolkit
// Copyright 2025-2026 Wells Consulting.
//

import Foundation

/// Size-based file rotation shared by ``Timber/TimberChannel`` (`.bySize`) and
/// ``TimberLineStore``.
enum TimberFileRotation {

    /// Renames `fileURL` to `rotatedURL` (dropping any existing file at
    /// `rotatedURL`) if `fileURL` has reached `thresholdBytes`.
    static func rotateIfNeeded(fileURL: URL, rotatedURL: URL, thresholdBytes: Int) {
        let fm = FileManager.default
        guard let attributes = try? fm.attributesOfItem(atPath: fileURL.path),
            let size = attributes[.size] as? Int,
            size >= thresholdBytes
        else { return }

        if fm.fileExists(atPath: rotatedURL.path) {
            try? fm.removeItem(at: rotatedURL)
        }
        try? fm.moveItem(at: fileURL, to: rotatedURL)
    }

    /// Appends `data` followed by a newline to `fileURL`, creating it if needed.
    static func appendLine(_ data: Data, to fileURL: URL) {
        var data = data
        data.append(UInt8(ascii: "\n"))

        if let handle = try? FileHandle(forWritingTo: fileURL) {
            handle.seekToEndOfFile()
            handle.write(data)
            handle.closeFile()
        } else {
            try? data.write(to: fileURL, options: .atomic)
        }
    }

    /// The newline-delimited lines of `fileURL`, or an empty array if the
    /// file does not exist or cannot be read.
    static func readLines(at fileURL: URL) -> [Data] {
        guard let data = try? Data(contentsOf: fileURL) else { return [] }
        return data.split(separator: UInt8(ascii: "\n")).map(Data.init)
    }

    /// Deletes `fileURL` and `rotatedURL` if they exist.
    static func deleteAll(fileURL: URL, rotatedURL: URL) throws {
        let fm = FileManager.default
        if fm.fileExists(atPath: fileURL.path) {
            try fm.removeItem(at: fileURL)
        }
        if fm.fileExists(atPath: rotatedURL.path) {
            try fm.removeItem(at: rotatedURL)
        }
    }
}
