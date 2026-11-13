//
// Motley – Michael's Swift Toolkit
// Copyright 2025-2026 Wells Consulting.
//

import Foundation
@testable import Motley
import Testing

struct TimberContextTests {

    // MARK: - Helpers

    private static func makeTempDir() throws -> URL {
        let dir = FileManager.default.temporaryDirectory
            .appendingPathComponent("TimberContextTests-\(UUID().uuidString)")
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

    // MARK: - Label

    @Test func withoutAScopeTheLabelIsJustTheFunction() {
        #expect(Timber.Context.current == nil)
        #expect(Timber.Context.label(function: "loadAccount()") == "loadAccount")
    }

    @Test func aScopePrefixesTheLabel() async {
        let label = await Timber.Context.withValue("settings") {
            Timber.Context.label(function: "loadAccount()")
        }

        #expect(label == "[settings] loadAccount")
    }

    @Test func aPurposeSaysWhyTheCallFired() async {
        let label = await Timber.Context.withValue("energy") {
            await Timber.Context.withPurpose("forecast-warmup") {
                Timber.Context.label(function: "dailyForecast()")
            }
        }

        #expect(label == "[energy > forecast-warmup] dailyForecast")
    }

    @Test func aPurposeWithoutAScopeStandsAlone() async {
        let label = await Timber.Context.withPurpose("warmup") {
            Timber.Context.label(function: "dailyForecast()")
        }

        #expect(label == "[warmup] dailyForecast")
    }

    // MARK: - Detail

    @Test func theDefaultDetailIsEveryCall() async {
        let detail = await Timber.Context.withValue("settings") {
            Timber.Context.detail
        }

        #expect(detail == .everyCall)
    }

    @Test func aPurposeKeepsTheEnclosingDetail() async {
        let detail = await Timber.Context.withValue("job", detail: .summaryOnly) {
            await Timber.Context.withPurpose("month") {
                Timber.Context.detail
            }
        }

        #expect(detail == .summaryOnly)
    }

    @Test func theScopeEndsWithTheClosure() async {
        _ = await Timber.Context.withValue("settings") { 1 }

        #expect(Timber.Context.current == nil)
        #expect(Timber.Context.detail == .everyCall)
    }

    // MARK: - Logging

    @Test func aSummaryOnlyScopeDropsCallsButKeepsWhatFollows() async throws {
        let dir = try Self.makeTempDir()
        defer { cleanUp(dir) }

        let channel = Timber.Channel(
            name: "context",
            directory: dir,
            rotation: .byCountAndAge(maxEntries: 100, maxAge: 60),
        )
        let log = Timber(subsystem: "test", channel: channel, minimumPersistedLevel: .debug)

        await Timber.Context.withValue("job", detail: .summaryOnly) {
            Timber.Context.logCall(log, "dropped")
        }
        Timber.Context.logCall(log, "kept")

        try await Self.waitUntil { await channel.entries.count == 1 }

        let entries = await channel.entries
        #expect(entries.count == 1)
        #expect(entries.first?.message.hasSuffix("| kept") == true)
    }

    @Test func aCallInsideAScopeCarriesTheLabel() async throws {
        let dir = try Self.makeTempDir()
        defer { cleanUp(dir) }

        let channel = Timber.Channel(
            name: "context",
            directory: dir,
            rotation: .byCountAndAge(maxEntries: 100, maxAge: 60),
        )
        let log = Timber(subsystem: "test", channel: channel, minimumPersistedLevel: .debug)

        await Timber.Context.withValue("settings") {
            Timber.Context.logCall(log)
        }

        try await Self.waitUntil { await channel.entries.count == 1 }

        let entries = await channel.entries
        #expect(entries.first?.message.hasPrefix("[settings] ") == true)
    }

    private func cleanUp(_ dir: URL) {
        do {
            try FileManager.default.removeItem(at: dir)
        } catch {
            // The temporary directory is fine to leave behind.
        }
    }
}
