//
// Motley – Michael's Swift Toolkit
// Copyright 2025-2026 Wells Consulting.
//

import Foundation

/// Builds a zip archive from files in a temporary directory.
///
/// Add files and directories, then call ``zipit()``. The archive is written to
/// the temporary directory, so move or copy it before the system clears that
/// directory.
public struct Zipper {

    private let filename: String
    private let stagingDir: URL

    private static let log = Timber()

    /// Creates a zipper for an archive with this name.
    public init(filename: String) {
        self.filename = filename
        let fm = FileManager.default
        self.stagingDir = fm.temporaryDirectory.appendingPathComponent(filename)
        do {
            try FileManager.default.createDirectory(
                at: stagingDir,
                withIntermediateDirectories: true,
            )
        } catch {
            Self.log.error(error, while: "creating staging directory")
        }
    }

    private func fileURL(for filename: String) -> URL {
        stagingDir.appendingPathComponent(filename)
    }

    /// Adds bytes as a file in the archive.
    public func addData(_ data: Data, as filename: String) throws {
        let url = fileURL(for: filename)
        try data.write(to: url, options: .atomic)
    }

    /// Adds text as a UTF-8 file in the archive.
    public func addText(_ text: String, as filename: String) throws {
        let url = fileURL(for: filename)
        try text.write(to: url, atomically: true, encoding: .utf8)
    }

    /// Adds a directory and everything under it.
    public func addDirectory(contentsOf sourceDir: URL, as name: String) throws {
        let destDir = stagingDir.appending(path: name, directoryHint: .isDirectory)
        try FileManager.default.copyItem(at: sourceDir, to: destDir)
    }

    /// Builds the archive and removes the staging directory.
    ///
    /// - Returns: The archive's URL, or `nil` if the copy failed.
    public func zipit() throws -> URL? {

        let fm = FileManager.default
        let zipDest = fm.temporaryDirectory.appendingPathComponent("\(filename).zip")

        var zipURL: URL?

        var coordinatorError: NSError?
        let coordinator = NSFileCoordinator()
        coordinator.coordinate(
            readingItemAt: stagingDir,
            options: .forUploading,
            error: &coordinatorError,
        ) { tempZipURL in
            do {
                if fm.fileExists(atPath: zipDest.path) {
                    do {
                        try fm.removeItem(at: zipDest)
                    } catch {
                        Self.log.error(error, while: "deleting pre-existing zip")
                    }
                }
                // Copy before the block returns — coordinator unlinks tempZipURL on exit.
                try fm.copyItem(at: tempZipURL, to: zipDest)
                zipURL = zipDest
            } catch {
                Self.log.error("Failed to copy zip: \(error)")
            }
        }

        if let err = coordinatorError {
            Self.log.error("NSFileCoordinator error: \(err)")
            throw err
        }

        do {
            try fm.removeItem(at: stagingDir)
        } catch {
            Self.log.error(error, while: "deleting staging directory")
        }

        return zipURL
    }
}
