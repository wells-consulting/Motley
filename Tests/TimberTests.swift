//
// Motley – Michael's Swift Toolkit
// Copyright 2025-2026 Wells Consulting.
//

import Foundation
import Synchronization
import Testing

@testable import Motley

// MARK: - Test Helpers

private func makeTempDir(_ label: String = #function) throws -> URL {
    let dir = FileManager.default.temporaryDirectory
        .appendingPathComponent("TimberTests-\(label)-\(UUID().uuidString)")
    try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
    return dir
}

private func cleanUp(_ dir: URL) {
    try? FileManager.default.removeItem(at: dir)
}

/// Polls `condition` until it returns `true`, or times out.
private func waitUntil(
    timeout: Duration = .milliseconds(2000),
    _ condition: () async -> Bool
) async throws {
    let deadline = ContinuousClock.now + timeout
    while ContinuousClock.now < deadline {
        if await condition() { return }
        try await Task.sleep(for: .milliseconds(10))
    }
}

/// A sendable latch for awaiting an arbitrary callback invocation.
private final class Expectation: Sendable {
    private let lock = Mutex<Bool>(false)

    func satisfy() {
        lock.withLock { $0 = true }
    }

    var isSatisfied: Bool {
        lock.withLock { $0 }
    }
}

// MARK: - Level

@Suite("Timber.Level")
struct TimberLevelTests {

    @Test("Level raw values match expected strings")
    func rawValues() {
        #expect(TimberLogLevel.debug.rawValue == "debug")
        #expect(TimberLogLevel.info.rawValue == "info")
        #expect(TimberLogLevel.notice.rawValue == "notice")
        #expect(TimberLogLevel.error.rawValue == "error")
    }

    @Test("Level can be initialized from raw value")
    func fromRawValue() {
        #expect(TimberLogLevel(rawValue: "debug") == .debug)
        #expect(TimberLogLevel(rawValue: "error") == .error)
        #expect(TimberLogLevel(rawValue: "unknown") == nil)
    }

    @Test("All five levels exist")
    func allLevels() {
        let levels: [TimberLogLevel] = [.debug, .info, .notice, .error]
        #expect(levels.count == 4)
    }

    @Test("Levels are ordered by severity")
    func ordering() {
        #expect(TimberLogLevel.debug < .info)
        #expect(TimberLogLevel.info < .notice)
        #expect(TimberLogLevel.notice < .error)
    }

    @Test("Same level is not less than itself")
    func equalityNotLessThan() {
        #expect(!(TimberLogLevel.error < .error))
        #expect(TimberLogLevel.error >= .error)
    }
}

// MARK: - Initialization

@Suite("Timber - Initialization")
struct TimberInitTests {

    @Test("Default init does not crash")
    func defaultInit() {
        let log = Timber()
        log.debug("init test")
    }

    @Test("Init with explicit subsystem and category")
    func explicitInit() {
        let log = Timber(subsystem: "com.test", category: "Tests")
        log.debug("explicit init test")
    }

    @Test("Init without a channel does not persist anything")
    func nilChannel() {
        let log = Timber(subsystem: "test", category: "sink")
        log.error("no crash")
    }
}

// MARK: - shortFile helper

@Suite("Timber.shortFile")
struct TimberShortFileTests {

    @Test("Strips module prefix and extension")
    func stripsModuleAndExtension() {
        #expect(Timber.shortFile("MyAppName/Labrador.swift") == "Labrador")
    }

    @Test("Strips base-class prefix when + is present")
    func stripsBaseClassPrefix() {
        #expect(Timber.shortFile("SomeApp/Some+Scene.swift") == "Scene")
        #expect(Timber.shortFile("SomeApp/Some+GraphQL.swift") == "GraphQL")
        #expect(Timber.shortFile("SomeApp/Some+ServerInfo.swift") == "ServerInfo")
        #expect(Timber.shortFile("SomeApp/Some+Settings.swift") == "Settings")
        #expect(Timber.shortFile("SomeApp/Some+Adapter.swift") == "Adapter")
    }

    @Test("Leaves names without + unchanged")
    func noPlus() {
        #expect(Timber.shortFile("SomeApp/SomeViewModel.swift") == "SomeViewModel")
        #expect(Timber.shortFile("SomeApp/SomeApp.swift") == "SomeApp")
    }

    @Test("Works when fileID has no slash")
    func noSlash() {
        #expect(Timber.shortFile("Labrador.swift") == "Labrador")
    }
}

// MARK: - defaultCategory helper

@Suite("Timber.defaultCategory")
struct TimberDefaultCategoryTests {

    @Test("Strips the module prefix and extension")
    func stripsModuleAndExtension() {
        #expect(Timber.defaultCategory(from: "MyAppName/Labrador.swift") == "Labrador")
    }

    @Test("Works when fileID has no slash")
    func noSlash() {
        #expect(Timber.defaultCategory(from: "Labrador.swift") == "Labrador")
    }

    @Test("Preserves subdirectory structure, stripping only the module prefix")
    func nested() {
        #expect(Timber.defaultCategory(from: "MyApp/Networking/APIClient.swift") == "Networking/APIClient")
        #expect(Timber.defaultCategory(from: "MyApp/UI/ProfileView.swift") == "UI/ProfileView")
    }

    @Test("Keeps a + suffix intact, unlike shortFile")
    func keepsPlusSuffix() {
        #expect(Timber.defaultCategory(from: "SomeApp/Some+Scene.swift") == "Some+Scene")
    }
}

// MARK: - LogEntry

#if canImport(os)

    @Suite("TimberLogEntry")
    struct TimberLogEntryTests {

        @Test("LogEntry is Codable round-trip")
        func codableRoundTrip() throws {
            let entry = TimberLogEntry(
                timestamp: Date(),
                level: .error,
                subsystem: "com.test",
                category: "Tests",
                message: "something broke",
                file: "Test.swift",
                function: "",
                line: 42
            )

            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(entry)

            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let decoded = try decoder.decode(TimberLogEntry.self, from: data)

            #expect(decoded.id == entry.id)
            #expect(decoded.level == entry.level)
            #expect(decoded.subsystem == entry.subsystem)
            #expect(decoded.category == entry.category)
            #expect(decoded.message == entry.message)
            #expect(decoded.file == entry.file)
            #expect(decoded.line == entry.line)
        }

        @Test("LogEntry has stable id for Identifiable")
        func identifiable() {
            let id = UUID()
            let entry = TimberLogEntry(
                id: id,
                timestamp: Date(),
                level: .error,
                subsystem: "com.test",
                category: "Tests",
                message: "msg",
                file: "F.swift",
                function: "",
                line: 1
            )
            #expect(entry.id == id)
        }
    }

    // MARK: - Timber + Channel

    @Suite("Timber - Channel routing")
    struct TimberChannelRoutingTests {

        @Test("Logging at or above minimumPersistedLevel persists to the channel")
        func persistsQualifyingLevels() async throws {
            let dir = try makeTempDir()
            defer { cleanUp(dir) }

            let channel = Timber.Channel(
                name: "test",
                directory: dir,
                rotation: .byCountAndAge(maxEntries: 500, maxAge: 7 * 24 * 60 * 60)
            )
            let log = Timber(
                subsystem: "test",
                category: "channel",
                channel: channel
            )

            log.error("persisted error")

            try await waitUntil { await channel.entries.count == 1 }

            let entries = await channel.entries
            #expect(entries[0].message == "persisted error")
            #expect(entries[0].level == .error)
        }

        @Test("Logging below minimumPersistedLevel is not persisted")
        func skipsBelowMinimumLevel() async throws {
            let dir = try makeTempDir()
            defer { cleanUp(dir) }

            let channel = Timber.Channel(
                name: "test",
                directory: dir,
                rotation: .byCountAndAge(maxEntries: 500, maxAge: 7 * 24 * 60 * 60)
            )
            let log = Timber(
                subsystem: "test",
                category: "channel",
                channel: channel
            )

            log.debug("not persisted")
            log.info("not persisted")

            // Give the actor a moment to process (both are below default .error).
            try await Task.sleep(for: .milliseconds(100))

            #expect(await channel.entries.isEmpty)
        }

        @Test("A custom minimumPersistedLevel widens what is persisted")
        func customMinimumLevel() async throws {
            let dir = try makeTempDir()
            defer { cleanUp(dir) }

            let channel = Timber.Channel(
                name: "test",
                directory: dir,
                rotation: .byCountAndAge(maxEntries: 500, maxAge: 7 * 24 * 60 * 60)
            )
            let log = Timber(
                subsystem: "test",
                category: "channel",
                channel: channel,
                minimumPersistedLevel: .notice
            )

            log.notice("persisted notice")

            try await waitUntil { await channel.entries.count == 1 }

            let entries = await channel.entries
            #expect(entries[0].message == "persisted notice")
            #expect(entries[0].level == .notice)
        }

        @Test("error(_:while:) formats and persists the composed message")
        func errorWithTaskPersists() async throws {
            let dir = try makeTempDir()
            defer { cleanUp(dir) }

            let channel = Timber.Channel(
                name: "test",
                directory: dir,
                rotation: .byCountAndAge(maxEntries: 500, maxAge: 7 * 24 * 60 * 60)
            )
            let log = Timber(
                subsystem: "test",
                category: "channel",
                channel: channel
            )

            log.error("timeout", while: "fetching data")

            try await waitUntil { await channel.entries.count == 1 }

            let entries = await channel.entries
            #expect(entries[0].message == "fetching data failed with error: timeout")
        }

        @Test(
            "One shared instance with a channel persists exactly the qualifying levels"
        )
        func persistsExactlyQualifyingLevels() async throws {
            let dir = try makeTempDir()
            defer { cleanUp(dir) }

            let channel = Timber.Channel(
                name: "levels",
                directory: dir,
                rotation: .byCountAndAge(maxEntries: 500, maxAge: 7 * 24 * 60 * 60)
            )
            let log = Timber(subsystem: "test", channel: channel, minimumPersistedLevel: .notice)

            log.debug("dropped debug")
            log.info("dropped info")
            log.notice("kept notice")
            log.error("kept error")

            try await waitUntil { await channel.entries.count == 2 }

            let entries = await channel.entries
            #expect(entries.map(\.level) == [.notice, .error])
            #expect(entries.map(\.message) == ["kept notice", "kept error"])
        }

        @Test("Persisted category is call-derived, not the instance category")
        func persistsCallDerivedCategory() async throws {
            let dir = try makeTempDir()
            defer { cleanUp(dir) }

            let channel = Timber.Channel(
                name: "shared",
                directory: dir,
                rotation: .byCountAndAge(maxEntries: 500, maxAge: 7 * 24 * 60 * 60)
            )
            // One shared, long-lived instance labeled "TraceLog" for os.Logger.
            let traceLog = Timber(
                subsystem: "Motley",
                category: "TraceLog",
                channel: channel,
                minimumPersistedLevel: .debug
            )

            // Call sites from different files on the same instance.
            traceLog.debug("network event", file: "Motley/Networking/APIClient.swift")
            traceLog.debug("ui event", file: "Motley/UI/ProfileView.swift")

            try await waitUntil { await channel.entries.count == 2 }

            let entries = await channel.entries
            #expect(!entries.contains { $0.category == "TraceLog" })
            let byCategory = Dictionary(grouping: entries, by: \.category)
            #expect(byCategory["Networking/APIClient"]?.first?.message == "network event")
            #expect(byCategory["UI/ProfileView"]?.first?.message == "ui event")
        }

        @Test("An explicit category overrides the call-derived one")
        func explicitCategoryOverrides() async throws {
            let dir = try makeTempDir()
            defer { cleanUp(dir) }

            let channel = Timber.Channel(
                name: "shared",
                directory: dir,
                rotation: .byCountAndAge(maxEntries: 500, maxAge: 7 * 24 * 60 * 60)
            )
            let log = Timber(subsystem: "Motley", channel: channel, minimumPersistedLevel: .debug)

            log.info("audit event", category: "AuditLog")

            try await waitUntil { await channel.entries.count == 1 }

            let entry = await channel.entries[0]
            #expect(entry.category == "AuditLog")
        }
    }

    // MARK: - Channel: byCountAndAge

    @Suite("Timber.Channel - byCountAndAge", .serialized)
    struct TimberChannelByCountAndAgeTests {

        @Test("Append and retrieve entries in chronological order")
        func appendAndRetrieve() async throws {
            let dir = try makeTempDir()
            defer { cleanUp(dir) }

            let channel = Timber.Channel(
                name: "log",
                directory: dir,
                rotation: .byCountAndAge(maxEntries: 500, maxAge: 7 * 24 * 60 * 60)
            )

            await channel.append(makeEntry(message: "not1", level: .notice), generation: 0)
            await channel.append(makeEntry(message: "err1", level: .error), generation: 0)

            let entries = await channel.entries
            #expect(entries.count == 2)
            #expect(entries[0].message == "not1")
            #expect(entries[1].message == "err1")
        }

        @Test("Entries persist across re-init from the same directory")
        func persistence() async throws {
            let dir = try makeTempDir()
            defer { cleanUp(dir) }

            let rotation = Timber.Channel.Rotation.byCountAndAge(
                maxEntries: 500,
                maxAge: 7 * 24 * 60 * 60
            )
            let channel1 = Timber.Channel(name: "log", directory: dir, rotation: rotation)
            await channel1.append(makeEntry(message: "persist me"), generation: 0)

            let channel2 = Timber.Channel(name: "log", directory: dir, rotation: rotation)
            let entries = await channel2.entries
            #expect(entries.count == 1)
            #expect(entries[0].message == "persist me")
        }

        @Test("deleteAll removes all entries and the backing file")
        func deleteAll() async throws {
            let dir = try makeTempDir()
            defer { cleanUp(dir) }

            let channel = Timber.Channel(
                name: "log",
                directory: dir,
                rotation: .byCountAndAge(maxEntries: 500, maxAge: 7 * 24 * 60 * 60)
            )
            await channel.append(makeEntry(message: "gone"), generation: 0)
            try await channel.deleteAll()

            #expect(await channel.entries.isEmpty)
            let fileURL = dir.appendingPathComponent("log.jsonl")
            #expect(!FileManager.default.fileExists(atPath: fileURL.path))
        }

        @Test("deleteAll increments the generation, dropping stale in-flight appends")
        func deleteAllIncrementsGeneration() async throws {
            let dir = try makeTempDir()
            defer { cleanUp(dir) }

            let channel = Timber.Channel(
                name: "log",
                directory: dir,
                rotation: .byCountAndAge(maxEntries: 500, maxAge: 7 * 24 * 60 * 60)
            )
            let staleGeneration = channel.currentGeneration
            #expect(staleGeneration == 0)

            try await channel.deleteAll()
            #expect(channel.currentGeneration == 1)

            await channel.append(makeEntry(message: "stale"), generation: staleGeneration)
            #expect(await channel.entries.isEmpty)
        }

        @Test("Append with matching generation succeeds")
        func appendWithMatchingGeneration() async throws {
            let dir = try makeTempDir()
            defer { cleanUp(dir) }

            let channel = Timber.Channel(
                name: "log",
                directory: dir,
                rotation: .byCountAndAge(maxEntries: 500, maxAge: 7 * 24 * 60 * 60)
            )
            await channel.append(makeEntry(message: "kept"), generation: channel.currentGeneration)
            #expect(await channel.entries.count == 1)
        }

        @Test("Entries are capped at maxEntries, dropping the oldest")
        func maxEntriesCap() async throws {
            let dir = try makeTempDir()
            defer { cleanUp(dir) }

            let maxEntries = 500
            let fileURL = dir.appendingPathComponent("log.jsonl")
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601

            var data = Data()
            for i in 0..<(maxEntries + 1) {
                let entry = makeEntry(message: "entry \(i)")
                data.append(try encoder.encode(entry))
                data.append(UInt8(ascii: "\n"))
            }
            try data.write(to: fileURL, options: .atomic)

            let channel = Timber.Channel(
                name: "log",
                directory: dir,
                rotation: .byCountAndAge(maxEntries: maxEntries, maxAge: 7 * 24 * 60 * 60)
            )

            let entries = await channel.entries
            #expect(entries.count == maxEntries)
            let messages = entries.map(\.message)
            #expect(!messages.contains("entry 0"))
            #expect(messages.contains("entry \(maxEntries)"))
        }

        @Test("Expired entries are pruned on load")
        func prunesExpiredOnLoad() async throws {
            let dir = try makeTempDir()
            defer { cleanUp(dir) }

            let maxAge: TimeInterval = 7 * 24 * 60 * 60
            let fileURL = dir.appendingPathComponent("log.jsonl")
            let expired = makeEntry(
                message: "old entry",
                timestamp: Date().addingTimeInterval(-(maxAge + 1))
            )
            let fresh = makeEntry(message: "new entry")

            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            var data = Data()
            data.append(try encoder.encode(expired))
            data.append(UInt8(ascii: "\n"))
            data.append(try encoder.encode(fresh))
            data.append(UInt8(ascii: "\n"))
            try data.write(to: fileURL, options: .atomic)

            let channel = Timber.Channel(
                name: "log",
                directory: dir,
                rotation: .byCountAndAge(maxEntries: 500, maxAge: maxAge)
            )
            let entries = await channel.entries
            #expect(entries.count == 1)
            #expect(entries[0].message == "new entry")
        }

        @Test("A short maxAge prunes stale entries appended during a session")
        func prunesWithShortMaxAge() async throws {
            let dir = try makeTempDir()
            defer { cleanUp(dir) }

            let maxAge: TimeInterval = 60
            let channel = Timber.Channel(
                name: "log",
                directory: dir,
                rotation: .byCountAndAge(maxEntries: 500, maxAge: maxAge)
            )
            await channel.append(
                makeEntry(message: "stale", timestamp: Date().addingTimeInterval(-(maxAge + 30))),
                generation: 0
            )
            await channel.append(makeEntry(message: "fresh"), generation: 0)

            // A re-init reloads the file and drops what is now past maxAge.
            let reloaded = Timber.Channel(
                name: "log",
                directory: dir,
                rotation: .byCountAndAge(maxEntries: 500, maxAge: maxAge)
            )
            let entries = await reloaded.entries
            #expect(entries.map(\.message) == ["fresh"])
        }

        @Test("Malformed lines are dropped, not thrown, on load")
        func dropsMalformedLinesOnLoad() async throws {
            let dir = try makeTempDir()
            defer { cleanUp(dir) }

            let fileURL = dir.appendingPathComponent("log.jsonl")
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            var data = try encoder.encode(makeEntry(message: "valid"))
            data.append(UInt8(ascii: "\n"))
            data.append(Data("not valid json".utf8))
            data.append(UInt8(ascii: "\n"))
            try data.write(to: fileURL, options: .atomic)

            let channel = Timber.Channel(
                name: "log",
                directory: dir,
                rotation: .byCountAndAge(maxEntries: 500, maxAge: 7 * 24 * 60 * 60)
            )
            let entries = await channel.entries
            #expect(entries.count == 1)
            #expect(entries[0].message == "valid")
        }
    }

    // MARK: - Channel: bySize

    @Suite("Timber.Channel - bySize", .serialized)
    struct TimberChannelBySizeTests {

        @Test("Appending below the threshold does not rotate")
        func noRotationBelowThreshold() async throws {
            let dir = try makeTempDir()
            defer { cleanUp(dir) }

            let channel = Timber.Channel(
                name: "trace",
                directory: dir,
                rotation: .bySize(thresholdBytes: 1_000_000)
            )
            await channel.append(makeEntry(message: "small"), generation: 0)

            let rotatedURL = dir.appendingPathComponent("trace.jsonl.1")
            #expect(!FileManager.default.fileExists(atPath: rotatedURL.path))
            #expect(await channel.entries.count == 1)
        }

        @Test("Exceeding the threshold rotates the current file to .1")
        func rotatesAtThreshold() async throws {
            let dir = try makeTempDir()
            defer { cleanUp(dir) }

            // Threshold small enough that a single entry's line exceeds it.
            let channel = Timber.Channel(
                name: "trace",
                directory: dir,
                rotation: .bySize(thresholdBytes: 10)
            )

            await channel.append(makeEntry(message: "first entry over threshold"), generation: 0)
            await channel.append(makeEntry(message: "second entry"), generation: 0)

            let rotatedURL = dir.appendingPathComponent("trace.jsonl.1")
            let currentURL = dir.appendingPathComponent("trace.jsonl")
            #expect(FileManager.default.fileExists(atPath: rotatedURL.path))
            #expect(FileManager.default.fileExists(atPath: currentURL.path))

            let entries = await channel.entries
            #expect(entries.count == 2)
            #expect(entries[0].message == "first entry over threshold")
            #expect(entries[1].message == "second entry")
        }

        @Test("Rotating a second time drops the prior .1 file")
        func rotationDropsPriorRotatedFile() async throws {
            let dir = try makeTempDir()
            defer { cleanUp(dir) }

            let channel = Timber.Channel(
                name: "trace",
                directory: dir,
                rotation: .bySize(thresholdBytes: 10)
            )

            await channel.append(makeEntry(message: "one"), generation: 0)
            await channel.append(makeEntry(message: "two"), generation: 0)
            await channel.append(makeEntry(message: "three"), generation: 0)

            let entries = await channel.entries
            // "one" was pushed into .1, then discarded when "two" rotated again.
            #expect(!entries.contains { $0.message == "one" })
            #expect(entries.contains { $0.message == "two" })
            #expect(entries.contains { $0.message == "three" })
        }

        @Test("deleteAll removes both the current and rotated files")
        func deleteAllRemovesBothFiles() async throws {
            let dir = try makeTempDir()
            defer { cleanUp(dir) }

            let channel = Timber.Channel(
                name: "trace",
                directory: dir,
                rotation: .bySize(thresholdBytes: 10)
            )
            await channel.append(makeEntry(message: "one"), generation: 0)
            await channel.append(makeEntry(message: "two"), generation: 0)

            try await channel.deleteAll()

            #expect(await channel.entries.isEmpty)
            #expect(
                !FileManager.default.fileExists(
                    atPath: dir.appendingPathComponent("trace.jsonl").path
                )
            )
            #expect(
                !FileManager.default.fileExists(
                    atPath: dir.appendingPathComponent("trace.jsonl.1").path
                )
            )
        }
    }

    // MARK: - TimberLineStore

    @Suite("TimberLineStore", .serialized)
    struct TimberLineStoreTests {

        @Test("Appended lines are retrievable in order")
        func appendAndRetrieve() async throws {
            let dir = try makeTempDir()
            defer { cleanUp(dir) }

            let store = TimberLineStore(
                directory: dir,
                fileName: "audit.log",
                thresholdBytes: 1_000_000
            )
            await store.append("first line")
            await store.append("second line")

            let lines = await store.lines
            #expect(lines == ["first line", "second line"])
        }

        @Test("Exceeding the threshold rotates the current file to .1")
        func rotatesAtThreshold() async throws {
            let dir = try makeTempDir()
            defer { cleanUp(dir) }

            let store = TimberLineStore(directory: dir, fileName: "audit.log", thresholdBytes: 10)
            await store.append("a line long enough to exceed the threshold")
            await store.append("second line")

            let rotatedURL = dir.appendingPathComponent("audit.log.1")
            let currentURL = dir.appendingPathComponent("audit.log")
            #expect(FileManager.default.fileExists(atPath: rotatedURL.path))
            #expect(FileManager.default.fileExists(atPath: currentURL.path))

            let lines = await store.lines
            #expect(lines == ["a line long enough to exceed the threshold", "second line"])
        }

        @Test("deleteAll removes both the current and rotated files")
        func deleteAllRemovesBothFiles() async throws {
            let dir = try makeTempDir()
            defer { cleanUp(dir) }

            let store = TimberLineStore(directory: dir, fileName: "audit.log", thresholdBytes: 10)
            await store.append("a line long enough to exceed the threshold")
            await store.append("second line")

            try await store.deleteAll()

            #expect(await store.lines.isEmpty)
            #expect(
                !FileManager.default.fileExists(
                    atPath: dir.appendingPathComponent("audit.log").path
                )
            )
            #expect(
                !FileManager.default.fileExists(
                    atPath: dir.appendingPathComponent("audit.log.1").path
                )
            )
        }
    }

    // MARK: - Channel: maxReadEntries

    @Suite("Timber.Channel - maxReadEntries", .serialized)
    struct TimberChannelMaxReadEntriesTests {

        @Test("byCountAndAge caps entries to the most recent maxReadEntries")
        func truncatesByCountAndAge() async throws {
            let dir = try makeTempDir()
            defer { cleanUp(dir) }

            let channel = Timber.Channel(
                name: "log",
                directory: dir,
                rotation: .byCountAndAge(maxEntries: 500, maxAge: 7 * 24 * 60 * 60),
                maxReadEntries: 2
            )
            for i in 0..<5 {
                await channel.append(makeEntry(message: "entry \(i)"), generation: 0)
            }

            let messages = await channel.entries.map(\.message)
            #expect(messages == ["entry 3", "entry 4"])
        }

        @Test("bySize caps the merged rotated+current entries to maxReadEntries")
        func truncatesBySize() async throws {
            let dir = try makeTempDir()
            defer { cleanUp(dir) }

            // Small threshold forces the first entry into the rotated file.
            let channel = Timber.Channel(
                name: "trace",
                directory: dir,
                rotation: .bySize(thresholdBytes: 10),
                maxReadEntries: 1
            )
            await channel.append(makeEntry(message: "one"), generation: 0)
            await channel.append(makeEntry(message: "two"), generation: 0)

            let messages = await channel.entries.map(\.message)
            #expect(messages == ["two"])
        }

        @Test("maxReadEntries nil returns all entries")
        func noCapByDefault() async throws {
            let dir = try makeTempDir()
            defer { cleanUp(dir) }

            let channel = Timber.Channel(
                name: "log",
                directory: dir,
                rotation: .byCountAndAge(maxEntries: 500, maxAge: 7 * 24 * 60 * 60)
            )
            await channel.append(makeEntry(message: "one"), generation: 0)
            await channel.append(makeEntry(message: "two"), generation: 0)

            #expect(await channel.entries.count == 2)
        }
    }

    // MARK: - Channel: Synchronous conveniences

    @Suite("Timber.Channel - appendSync/deleteAllSync", .serialized)
    struct TimberChannelSyncConvenienceTests {

        @Test("appendSync persists the entry without awaiting")
        func appendSync() async throws {
            let dir = try makeTempDir()
            defer { cleanUp(dir) }

            let channel = Timber.Channel(
                name: "log",
                directory: dir,
                rotation: .byCountAndAge(maxEntries: 500, maxAge: 7 * 24 * 60 * 60)
            )
            channel.appendSync(makeEntry(message: "sync appended"))

            try await waitUntil { await channel.entries.count == 1 }
            #expect(await channel.entries.first?.message == "sync appended")
        }

        @Test("deleteAllSync removes all entries without awaiting")
        func deleteAllSync() async throws {
            let dir = try makeTempDir()
            defer { cleanUp(dir) }

            let channel = Timber.Channel(
                name: "log",
                directory: dir,
                rotation: .byCountAndAge(maxEntries: 500, maxAge: 7 * 24 * 60 * 60)
            )
            await channel.append(makeEntry(message: "gone"), generation: 0)

            channel.deleteAllSync()

            try await waitUntil { await channel.entries.isEmpty }
            #expect(
                !FileManager.default.fileExists(
                    atPath: dir.appendingPathComponent("log.jsonl").path
                )
            )
        }

        @Test("deleteAllSync onFailure fires when deleteAll throws")
        func deleteAllSyncOnFailure() async throws {
            let dir = try makeTempDir()
            defer { cleanUp(dir) }

            let channel = Timber.Channel(
                name: "log",
                directory: dir,
                rotation: .byCountAndAge(maxEntries: 500, maxAge: 7 * 24 * 60 * 60)
            )
            await channel.append(makeEntry(message: "locked"), generation: 0)

            // Immutable files cannot be removed, so deleteAll is guaranteed to throw.
            let fileURL = dir.appendingPathComponent("log.jsonl")
            try FileManager.default.setAttributes([.immutable: true], ofItemAtPath: fileURL.path)
            defer {
                try? FileManager.default.setAttributes(
                    [.immutable: false],
                    ofItemAtPath: fileURL.path
                )
            }

            let failureExpectation = Expectation()
            channel.deleteAllSync { _ in
                failureExpectation.satisfy()
            }

            try await waitUntil { failureExpectation.isSatisfied }
        }
    }

    // MARK: - Test Fixtures

    private func makeEntry(
        message: String,
        level: TimberLogLevel = .error,
        timestamp: Date = Date()
    ) -> TimberLogEntry {
        TimberLogEntry(
            timestamp: timestamp,
            level: level,
            subsystem: "s",
            category: "c",
            message: message,
            file: "Test.swift",
            function: "",
            line: 1
        )
    }

#endif
