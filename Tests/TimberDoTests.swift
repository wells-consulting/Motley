//
// Motley – Michael's Swift Toolkit
// Copyright 2025-2026 Wells Consulting.
//

import Foundation
@testable import Motley
import Testing

struct TimberDoTests {

    private struct Boom: Error {}

    // MARK: - Helpers

    private static func makeTempDir() throws -> URL {
        let dir = FileManager.default.temporaryDirectory
            .appendingPathComponent("TimberDoTests-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    private static func waitUntil(
        timeout: Duration = .milliseconds(2_000),
        _ condition: () async -> Bool,
    ) async throws {
        let deadline = ContinuousClock.now + timeout
        while ContinuousClock.now < deadline {
            if await condition() { return }
            try await Task.sleep(for: .milliseconds(10))
        }
    }

    private func cleanUp(_ dir: URL) {
        do {
            try FileManager.default.removeItem(at: dir)
        } catch {
            // The temporary directory is fine to leave behind.
        }
    }

    // MARK: - Sync

    @Test func aValueComesBack() {
        let log = Timber()

        let value: Int? = log.do("reading") { 42 }

        #expect(value == 42)
    }

    @Test func aFailureBecomesNil() {
        let log = Timber()

        let value: Int? = log.do("reading") { throw Boom() }

        #expect(value == nil)
    }

    @Test func aCancellationIsNotAFailure() {
        let log = Timber()

        let value: Int? = log.do("reading") { throw CancellationError() }

        #expect(value == nil)
    }

    @Test func theVoidFormRunsTheOperation() {
        let log = Timber()
        var ran = false

        log.do("reading") { ran = true }

        #expect(ran)
    }

    // MARK: - Async

    @Test func anAsyncValueComesBack() async {
        let log = Timber()

        let value: Int? = await log.do("reading") { 42 }

        #expect(value == 42)
    }

    @Test func anAsyncFailureBecomesNil() async {
        let log = Timber()

        let value: Int? = await log.do("reading") { throw Boom() }

        #expect(value == nil)
    }

    @Test func anAsyncCancellationIsNotAFailure() async {
        let log = Timber()

        let value: Int? = await log.do("reading") { throw CancellationError() }

        #expect(value == nil)
    }

    @Test func theAsyncVoidFormRunsTheOperation() async {
        let log = Timber()
        var ran = false

        await log.do("reading") { ran = true }

        #expect(ran)
    }

    // MARK: - Logging

    @Test func aFailureIsLoggedWithItsTask() async throws {
        let dir = try Self.makeTempDir()
        defer { cleanUp(dir) }

        let channel = Timber.Channel(
            name: "do",
            directory: dir,
            rotation: .byCountAndAge(maxEntries: 100, maxAge: 60),
        )
        let log = Timber(subsystem: "test", channel: channel, minimumPersistedLevel: .debug)

        _ = log.do("reading the account") { throw Boom() }

        try await Self.waitUntil { await channel.entries.count == 1 }

        let entries = await channel.entries
        #expect(entries.first?.message.contains("reading the account failed with error") == true)
    }

    @Test func aCancellationIsNotLogged() async throws {
        let dir = try Self.makeTempDir()
        defer { cleanUp(dir) }

        let channel = Timber.Channel(
            name: "do",
            directory: dir,
            rotation: .byCountAndAge(maxEntries: 100, maxAge: 60),
        )
        let log = Timber(subsystem: "test", channel: channel, minimumPersistedLevel: .debug)

        _ = log.do("reading the account") { throw CancellationError() }
        _ = log.do("another task") { throw Boom() }

        // Only the real failure is written, so a cancellation leaves no line.
        try await Self.waitUntil { await channel.entries.count == 1 }

        let entries = await channel.entries
        #expect(entries.first?.message.contains("another task failed with error") == true)
    }
}
