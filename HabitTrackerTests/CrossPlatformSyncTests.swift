import XCTest
import SwiftData
@testable import HabitTracker

/// Verifies that data written by one HabitStore is immediately visible to a second HabitStore
/// backed by the same on-disk store file.
///
/// CloudKit mirroring guarantees that once a record is flushed to the local SQLite store it is
/// queued for sync and will appear on other devices after the CloudKit push/pull cycle completes.
/// These tests cover the local half of that guarantee: a fresh container reading the same file
/// sees whatever the first container wrote.
@MainActor
final class CrossPlatformSyncTests: XCTestCase {

    private var storeURL: URL!

    override func setUp() async throws {
        let dir = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        storeURL = dir.appendingPathComponent("sync_test.sqlite")
    }

    override func tearDown() async throws {
        try? FileManager.default.removeItem(at: storeURL.deletingLastPathComponent())
    }

    private func makeStore() throws -> HabitStore {
        let config = ModelConfiguration(url: storeURL)
        let container = try ModelContainer(for: AppConfig.schema, configurations: config)
        return HabitStore(container: { container }, performsSideEffects: false)
    }

    // MARK: - Habit CRUD

    func testHabitAddedByOneStoreIsReadableByAnother() throws {
        let a = try makeStore()
        a.addHabit(Habit(name: "Meditate"))
        a.save()

        let b = try makeStore()
        XCTAssertEqual(b.fetchHabits().count, 1)
        XCTAssertEqual(b.fetchHabits().first?.name, "Meditate")
    }

    // Cross-container deletion is NOT tested here: CloudKit propagates deletes via tombstones,
    // not by one container reading another's SQLite WAL checkpoint. Deletion within a single
    // store instance is covered by HabitStoreTests.

    // MARK: - Completions

    func testCompletionWrittenByOneStoreIsVisibleToAnother() throws {
        let a = try makeStore()
        let habit = Habit(name: "Run")
        a.addHabit(habit)
        let today = Date.now
        a.toggleCompletion(for: habit, on: today)
        a.save()

        let b = try makeStore()
        let fetched = try XCTUnwrap(b.fetchHabits().first)
        XCTAssertTrue(fetched.isCompleted(on: today))
    }

    func testUndoCompletionIsVisibleToAnother() throws {
        let a = try makeStore()
        let habit = Habit(name: "Read")
        a.addHabit(habit)
        let today = Date.now
        a.toggleCompletion(for: habit, on: today)
        a.toggleCompletion(for: habit, on: today) // undo
        a.save()

        let b = try makeStore()
        let fetched = try XCTUnwrap(b.fetchHabits().first)
        XCTAssertFalse(fetched.isCompleted(on: today))
    }

    // MARK: - Skip / unskip

    func testSkipWithReasonSurvivesRoundTrip() throws {
        let a = try makeStore()
        let habit = Habit(name: "Journal")
        a.addHabit(habit)
        let today = Date.now
        a.skipDay(for: habit, on: today, reason: "Sick day")
        a.save()

        let b = try makeStore()
        let fetched = try XCTUnwrap(b.fetchHabits().first)
        XCTAssertTrue(fetched.isSkipped(on: today))
        XCTAssertEqual(fetched.entry(for: today)?.skipReason, "Sick day")
    }

    func testUnskipIsVisibleToAnother() throws {
        let a = try makeStore()
        let habit = Habit(name: "Stretch")
        a.addHabit(habit)
        let today = Date.now
        a.skipDay(for: habit, on: today)
        a.unskipDay(for: habit, on: today)
        a.save()

        let b = try makeStore()
        let fetched = try XCTUnwrap(b.fetchHabits().first)
        XCTAssertFalse(fetched.isSkipped(on: today))
    }

    // MARK: - Habit metadata

    func testHabitRenameIsVisibleToAnother() throws {
        let a = try makeStore()
        let habit = Habit(name: "Old Name")
        a.addHabit(habit)
        a.save()

        habit.name = "New Name"
        a.save()

        let b = try makeStore()
        XCTAssertEqual(b.fetchHabits().first?.name, "New Name")
    }

    func testEmojiAndColorSurviveRoundTrip() throws {
        let a = try makeStore()
        let habit = Habit(name: "Water", emoji: "💧", color: .teal)
        a.addHabit(habit)
        a.save()

        let b = try makeStore()
        let fetched = try XCTUnwrap(b.fetchHabits().first)
        XCTAssertEqual(fetched.emoji, "💧")
        XCTAssertEqual(fetched.color, .teal)
    }
}
