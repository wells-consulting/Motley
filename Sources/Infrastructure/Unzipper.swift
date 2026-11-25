//
// Motley – Michael's Swift Toolkit
// Copyright 2025-2026 Wells Consulting.
//

import Compression
import Foundation

/// Reads files out of a zip in memory. ``Zipper`` writes them; this reads
/// them.
///
/// Only stored and DEFLATE entries, no encryption and no zip64, which is what
/// an `.xlsx` workbook uses. Small archives only, since it unzips all at once.
public struct Unzipper {

    // MARK: - Errors

    /// Why the archive or one of its entries couldn't be read.
    public enum ReadError: Error, LocalizedError, Sendable {

        /// The data isn't a zip archive.
        case notAZipArchive
        /// The entry uses compression this reader doesn't handle.
        case unsupportedEntry(String)
        /// The entry's data is damaged.
        case corruptEntry(String)

        public var errorDescription: String? {
            switch self {
            case .notAZipArchive:
                "The file isn't a zip archive."
            case let .unsupportedEntry(name):
                "\(name) is compressed in a way this reader doesn't handle."
            case let .corruptEntry(name):
                "\(name) couldn't be read – the file may be damaged."
            }
        }
    }

    // MARK: - Entry

    private struct Entry {
        let method: UInt16
        let compressedSize: Int
        let uncompressedSize: Int
        let localHeaderOffset: Int
    }

    // MARK: - Fields

    private let data: Data
    private let entries: [String: Entry]

    // MARK: - Initializer

    /// Reads the archive's directory.
    ///
    /// - Throws: ``ReadError/notAZipArchive`` when the data isn't a zip.
    public init(data: Data) throws {
        self.data = data
        entries = try Self.centralDirectory(of: data)
    }

    // MARK: - Reading

    /// Every file in the archive, sorted.
    public var fileNames: [String] {
        entries.keys.sorted()
    }

    /// The file's bytes, or `nil` when there's no such file.
    public func contents(of path: String) throws -> Data? {
        guard let entry = entries[path] else {
            return nil
        }

        let header = entry.localHeaderOffset
        guard data.count >= header + 30, data.uint32(at: header) == 0x0403_4B50 else {
            throw ReadError.corruptEntry(path)
        }

        let start = header + 30 + Int(data.uint16(at: header + 26)) + Int(data.uint16(at: header + 28))
        guard start + entry.compressedSize <= data.count else {
            throw ReadError.corruptEntry(path)
        }
        let compressed = data.subdata(in: start..<(start + entry.compressedSize))

        switch entry.method {
        case 0:
            return compressed
        case 8:
            return try Self.inflate(compressed, size: entry.uncompressedSize, name: path)
        default:
            throw ReadError.unsupportedEntry(path)
        }
    }

    // MARK: - Layout

    /// The end of central directory record is in the last 64 KB (its comment
    /// can be up to that long), and it says where the directory is.
    private static func centralDirectory(of data: Data) throws -> [String: Entry] {
        guard data.count >= 22 else {
            throw ReadError.notAZipArchive
        }

        let earliest = max(0, data.count - 22 - 65_535)
        guard
            let end = stride(from: data.count - 22, through: earliest, by: -1)
                .first(where: { data.uint32(at: $0) == 0x0605_4B50 })
        else {
            throw ReadError.notAZipArchive
        }

        let count = Int(data.uint16(at: end + 10))
        var offset = Int(data.uint32(at: end + 16))
        var entries: [String: Entry] = [:]

        for _ in 0..<count {
            guard data.count >= offset + 46, data.uint32(at: offset) == 0x0201_4B50 else {
                throw ReadError.notAZipArchive
            }

            let nameLength = Int(data.uint16(at: offset + 28))
            let extraLength = Int(data.uint16(at: offset + 30))
            let commentLength = Int(data.uint16(at: offset + 32))

            guard data.count >= offset + 46 + nameLength else {
                throw ReadError.notAZipArchive
            }
            guard
                let name = String(
                    bytes: data.subdata(in: (offset + 46)..<(offset + 46 + nameLength)),
                    encoding: .utf8,
                )
            else {
                throw ReadError.notAZipArchive
            }

            entries[name] = Entry(
                method: data.uint16(at: offset + 10),
                compressedSize: Int(data.uint32(at: offset + 20)),
                uncompressedSize: Int(data.uint32(at: offset + 24)),
                localHeaderOffset: Int(data.uint32(at: offset + 42)),
            )
            offset += 46 + nameLength + extraLength + commentLength
        }

        return entries
    }

    /// Raw DEFLATE, which `COMPRESSION_ZLIB` decodes (there's no zlib header).
    private static func inflate(_ compressed: Data, size: Int, name: String) throws -> Data {
        guard size > 0 else {
            return Data()
        }

        var output = Data(count: size)
        let written = output.withUnsafeMutableBytes { destination in
            compressed.withUnsafeBytes { source in
                guard let destination = destination.bindMemory(to: UInt8.self).baseAddress,
                    let source = source.bindMemory(to: UInt8.self).baseAddress
                else {
                    return 0
                }

                return compression_decode_buffer(
                    destination,
                    size,
                    source,
                    compressed.count,
                    nil,
                    COMPRESSION_ZLIB,
                )
            }
        }

        guard written == size else {
            throw ReadError.corruptEntry(name)
        }

        return output
    }
}

extension Data {

    // Zip numbers are little-endian.
    fileprivate func uint16(at offset: Int) -> UInt16 {
        guard offset + 2 <= count else {
            return 0
        }

        return UInt16(self[startIndex + offset]) | UInt16(self[startIndex + offset + 1]) << 8
    }

    fileprivate func uint32(at offset: Int) -> UInt32 {
        guard offset + 4 <= count else {
            return 0
        }

        return (0..<4).reduce(0) { value, byte in
            value | UInt32(self[startIndex + offset + byte]) << (8 * byte)
        }
    }
}
