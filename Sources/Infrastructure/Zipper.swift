//
// Motley – Michael's Swift Toolkit
// Copyright 2025-2026 Wells Consulting.
//

import Foundation

public struct Zipper {

    private let filename: String
    private let stagingDir: URL

    private static let log = Timber()

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

    public func addData(_ data: Data, as filename: String) throws {
        let url = fileURL(for: filename)
        try data.write(to: url, options: .atomic)
    }

    public func addText(_ text: String, as filename: String) throws {
        let url = fileURL(for: filename)
        try text.write(to: url, atomically: true, encoding: .utf8)
    }

    public func addDirectory(contentsOf sourceDir: URL, as name: String) throws {
        let destDir = stagingDir.appending(path: name, directoryHint: .isDirectory)
        try FileManager.default.copyItem(at: sourceDir, to: destDir)
    }

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
