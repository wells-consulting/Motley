//
// Motley – Michael's Swift Toolkit
// Copyright 2025-2026 Wells Consulting.
//

import Compression
import Foundation
@testable import Motley
import Testing

struct UnzipperTests {

    // MARK: - Fixtures

    private struct File {
        let name: String
        let data: Data
        let deflate: Bool
    }

    /// Builds a zip in memory, so the test doesn't depend on the system's zip
    /// tool or on what a spreadsheet app happens to write.
    private static func zip(_ files: [File]) -> Data {
        var output = Data()
        var directory = Data()
        var count: UInt16 = 0

        for file in files {
            let name = Data(file.name.utf8)
            let payload = file.deflate ? Self.deflate(file.data) : file.data
            let offset = UInt32(output.count)

            output.append(uint32: 0x0403_4B50)
            output.append(uint16: 20)
            output.append(uint16: 0)
            output.append(uint16: file.deflate ? 8 : 0)
            output.append(uint16: 0)
            output.append(uint16: 0)
            output.append(uint32: 0)
            output.append(uint32: UInt32(payload.count))
            output.append(uint32: UInt32(file.data.count))
            output.append(uint16: UInt16(name.count))
            output.append(uint16: 0)
            output.append(name)
            output.append(payload)

            directory.append(uint32: 0x0201_4B50)
            directory.append(uint16: 20)
            directory.append(uint16: 20)
            directory.append(uint16: 0)
            directory.append(uint16: file.deflate ? 8 : 0)
            directory.append(uint16: 0)
            directory.append(uint16: 0)
            directory.append(uint32: 0)
            directory.append(uint32: UInt32(payload.count))
            directory.append(uint32: UInt32(file.data.count))
            directory.append(uint16: UInt16(name.count))
            directory.append(uint16: 0)
            directory.append(uint16: 0)
            directory.append(uint16: 0)
            directory.append(uint16: 0)
            directory.append(uint32: 0)
            directory.append(uint32: offset)
            directory.append(name)

            count += 1
        }

        let directoryOffset = UInt32(output.count)
        output.append(directory)
        output.append(uint32: 0x0605_4B50)
        output.append(uint16: 0)
        output.append(uint16: 0)
        output.append(uint16: count)
        output.append(uint16: count)
        output.append(uint32: UInt32(directory.count))
        output.append(uint32: directoryOffset)
        output.append(uint16: 0)

        return output
    }

    private static func deflate(_ data: Data) -> Data {
        var output = Data(count: data.count + 64)

        let written = output.withUnsafeMutableBytes { destination in
            data.withUnsafeBytes { source in
                guard let destination = destination.bindMemory(to: UInt8.self).baseAddress,
                    let source = source.bindMemory(to: UInt8.self).baseAddress
                else {
                    return 0
                }

                return compression_encode_buffer(
                    destination,
                    data.count + 64,
                    source,
                    data.count,
                    nil,
                    COMPRESSION_ZLIB,
                )
            }
        }

        return output.prefix(written)
    }

    private static let text = String(repeating: "The meter is read once an hour. ", count: 40)

    // MARK: - Tests

    @Test func aStoredEntryComesBack() throws {
        let archive = Self.zip([File(name: "stored.txt", data: Data(Self.text.utf8), deflate: false)])
        let unzipper = try Unzipper(data: archive)

        let contents = try unzipper.contents(of: "stored.txt")

        #expect(contents.map { String(decoding: $0, as: UTF8.self) } == Self.text)
    }

    @Test func aDeflatedEntryComesBack() throws {
        let archive = Self.zip([File(name: "deflated.txt", data: Data(Self.text.utf8), deflate: true)])
        let unzipper = try Unzipper(data: archive)

        let contents = try unzipper.contents(of: "deflated.txt")

        #expect(contents.map { String(decoding: $0, as: UTF8.self) } == Self.text)
    }

    @Test func everyFileIsListedInOrder() throws {
        let archive = Self.zip([
            File(name: "b.txt", data: Data("b".utf8), deflate: false),
            File(name: "a.txt", data: Data("a".utf8), deflate: true),
        ])
        let unzipper = try Unzipper(data: archive)

        #expect(unzipper.fileNames == ["a.txt", "b.txt"])
    }

    @Test func aFileThatIsNotThereIsNil() throws {
        let archive = Self.zip([File(name: "a.txt", data: Data("a".utf8), deflate: false)])
        let unzipper = try Unzipper(data: archive)

        #expect(try unzipper.contents(of: "missing.txt") == nil)
    }

    @Test func somethingThatIsNotAZipIsRejected() {
        #expect(throws: Unzipper.ReadError.self) {
            try Unzipper(data: Data("not a zip".utf8))
        }
    }
}

// MARK: - Little-endian

private extension Data {

    mutating func append(uint16 value: UInt16) {
        append(contentsOf: [UInt8(value & 0xFF), UInt8((value >> 8) & 0xFF)])
    }

    mutating func append(uint32 value: UInt32) {
        append(
            contentsOf: [
                UInt8(value & 0xFF),
                UInt8((value >> 8) & 0xFF),
                UInt8((value >> 16) & 0xFF),
                UInt8((value >> 24) & 0xFF),
            ]
        )
    }
}
