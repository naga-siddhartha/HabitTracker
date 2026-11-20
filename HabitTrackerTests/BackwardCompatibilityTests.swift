import XCTest
import SwiftData
@testable import HabitTracker

/// Verifies that backups written by older versions of the app restore cleanly in the current
/// version. Each test fixture represents a JSON snapshot from a specific release era and asserts
/// that existing-user data is preserved exactly — no silent drops or changed defaults.
@MainActor
final class BackwardCompatibilityTests: XCTestCase {

    private func makeContext() throws -> ModelContext {
        let container = try ModelContainer(
            for: AppConfig.schema,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        return ModelContext(container)
    }

    private func restore(_ json: String) throws -> [Habit] {
        let data = try XCTUnwrap(json.data(using: .utf8))
        let parsed = try ImportService.parseExportData(data)
        let ctx = try makeContext()
        try ImportService.replaceAllAndRestore(from: parsed, context: ctx)
        return try ctx.fetch(FetchDescriptor<Habit>())
    }

    // MARK: - v1.0 era (no optional fields)

    func testV1MinimalHabitRestores() throws {
        let json = """
        {"appVersion":"1.0","exportDate":"2025-01-15T00:00:00Z","habits":[{
          "id":"AAAAAAAA-0000-0000-0000-000000000001",
          "name":"Read","color":"blue","frequency":"daily",
          "activeDays":[],"createdAt":"2024-11-01T00:00:00Z","isArchived":false,
          "currentStreak":5,"longestStreak":10,"entries":[]
        }]}
        """
        let habits = try restore(json)
        XCTAssertEqual(habits.count, 1)
        let h = try XCTUnwrap(habits.first)
        XCTAssertEqual(h.name, "Read")
        XCTAssertEqual(h.color, .blue)
        XCTAssertEqual(h.frequency, .daily)
        XCTAssertFalse(h.isArchived)
        // Reminder fields introduced in 1.4 default to empty/zero
        XCTAssertEqual(h.reminderTimes, [])
        XCTAssertEqual(h.reminderIntervalMinutes, 0)
        XCTAssertNil(h.emoji)
    }

    // MARK: - ID preservation (critical for CloudKit dedup)

    func testHabitIDIsPreservedOnRestore() throws {
        let knownID = "BBBBBBBB-1111-1111-1111-000000000002"
        let json = """
        {"appVersion":"1.2","exportDate":"2025-06-01T00:00:00Z","habits":[{
          "id":"\(knownID)","name":"Meditate","color":"purple","frequency":"daily",
          "activeDays":[],"createdAt":"2025-01-01T00:00:00Z","isArchived":false,
          "currentStreak":0,"longestStreak":0,"entries":[]
        }]}
        """
        let habits = try restore(json)
        XCTAssertEqual(habits.first?.id, UUID(uuidString: knownID))
    }

    // MARK: - Unknown enum values degrade gracefully

    func testUnknownColorFallsBackToBlue() throws {
        let json = """
        {"appVersion":"1.1","exportDate":"2025-03-01T00:00:00Z","habits":[{
          "id":"CCCCCCCC-0000-0000-0000-000000000003",
          "name":"Yoga","color":"aquamarine","frequency":"daily",
          "activeDays":[],"createdAt":"2025-01-01T00:00:00Z","isArchived":false,
          "currentStreak":0,"longestStreak":0,"entries":[]
        }]}
        """
        let habits = try restore(json)
        XCTAssertEqual(habits.first?.color, .blue)
    }

    func testUnknownFrequencyFallsBackToDaily() throws {
        let json = """
        {"appVersion":"1.1","exportDate":"2025-03-01T00:00:00Z","habits":[{
          "id":"DDDDDDDD-0000-0000-0000-000000000004",
          "name":"Stretch","color":"green","frequency":"biweekly",
          "activeDays":[],"createdAt":"2025-01-01T00:00:00Z","isArchived":false,
          "currentStreak":0,"longestStreak":0,"entries":[]
        }]}
        """
        let habits = try restore(json)
        XCTAssertEqual(habits.first?.frequency, .daily)
    }

    func testUnknownWeekdayNamesAreDroppedSilently() throws {
        let json = """
        {"appVersion":"1.1","exportDate":"2025-03-01T00:00:00Z","habits":[{
          "id":"EEEEEEEE-0000-0000-0000-000000000005",
          "name":"Run","color":"red","frequency":"weekly",
          "activeDays":["Monday","Funday","Wednesday"],
          "createdAt":"2025-01-01T00:00:00Z","isArchived":false,
          "currentStreak":0,"longestStreak":0,"entries":[]
        }]}
        """
        let habits = try restore(json)
        // "Funday" is dropped; Monday and Wednesday survive
        XCTAssertEqual(habits.first?.activeDays, [.monday, .wednesday])
    }

    // MARK: - Entry fields

    func testEntriesWithoutCompletionCountDefaultToZero() throws {
        let json = """
        {"appVersion":"1.3","exportDate":"2025-09-01T00:00:00Z","habits":[{
          "id":"FFFFFFFF-0000-0000-0000-000000000006",
          "name":"Walk","color":"teal","frequency":"daily",
          "activeDays":[],"createdAt":"2025-08-01T00:00:00Z","isArchived":false,
          "currentStreak":3,"longestStreak":3,
          "entries":[{"date":"2025-08-30T05:00:00Z","isCompleted":true,"isSkipped":false,"skipReason":null}]
        }]}
        """
        let habits = try restore(json)
        let entry = try XCTUnwrap(habits.first?.entriesOrEmpty.first)
        XCTAssertEqual(entry.completionCount, 0)
        XCTAssertTrue(entry.isCompleted)
    }

    func testSkipReasonPreservedFromOldBackup() throws {
        let json = """
        {"appVersion":"1.3","exportDate":"2025-09-01T00:00:00Z","habits":[{
          "id":"GGGGGGGG-0000-0000-0000-000000000007",
          "name":"Gym","color":"orange","frequency":"daily",
          "activeDays":[],"createdAt":"2025-08-01T00:00:00Z","isArchived":false,
          "currentStreak":0,"longestStreak":5,
          "entries":[{"date":"2025-08-28T05:00:00Z","isCompleted":false,"isSkipped":true,"skipReason":"Sick"}]
        }]}
        """
        let habits = try restore(json)
        let entry = try XCTUnwrap(habits.first?.entriesOrEmpty.first)
        XCTAssertTrue(entry.isSkipped)
        XCTAssertEqual(entry.skipReason, "Sick")
    }

    // MARK: - v1.4 fields (emoji, reminders, completionCount)

    func testV14EmojiAndRemindersRestoreCorrectly() throws {
        let json = """
        {"appVersion":"1.4","exportDate":"2026-01-01T00:00:00Z","habits":[{
          "id":"HHHHHHHH-0000-0000-0000-000000000008",
          "name":"Drink Water","color":"teal","frequency":"daily",
          "activeDays":[],"createdAt":"2025-10-01T00:00:00Z","isArchived":false,
          "currentStreak":1,"longestStreak":1,
          "emoji":"💧","reminderIntervalMinutes":60,
          "entries":[{"date":"2026-01-01T05:00:00Z","isCompleted":true,"isSkipped":false,"skipReason":null,"completionCount":3}]
        }]}
        """
        let habits = try restore(json)
        let h = try XCTUnwrap(habits.first)
        XCTAssertEqual(h.emoji, "💧")
        XCTAssertEqual(h.reminderIntervalMinutes, 60)
        XCTAssertEqual(h.entriesOrEmpty.first?.completionCount, 3)
    }

    // MARK: - Multi-habit backup

    func testMultipleHabitsAllRestore() throws {
        let json = """
        {"appVersion":"1.2","exportDate":"2025-07-01T00:00:00Z","habits":[
          {"id":"11111111-0000-0000-0000-000000000001","name":"Run","color":"red","frequency":"daily",
           "activeDays":[],"createdAt":"2025-01-01T00:00:00Z","isArchived":false,
           "currentStreak":0,"longestStreak":0,"entries":[]},
          {"id":"22222222-0000-0000-0000-000000000002","name":"Read","color":"blue","frequency":"daily",
           "activeDays":[],"createdAt":"2025-01-02T00:00:00Z","isArchived":false,
           "currentStreak":0,"longestStreak":0,"entries":[]},
          {"id":"33333333-0000-0000-0000-000000000003","name":"Meditate","color":"purple","frequency":"weekly",
           "activeDays":["Monday","Friday"],"createdAt":"2025-01-03T00:00:00Z","isArchived":false,
           "currentStreak":0,"longestStreak":0,"entries":[]}
        ]}
        """
        let habits = try restore(json)
        XCTAssertEqual(habits.count, 3)
        let names = Set(habits.map(\.name))
        XCTAssertEqual(names, ["Run", "Read", "Meditate"])
    }

    // MARK: - Archived habits are preserved

    func testArchivedHabitRestoresAsArchived() throws {
        let json = """
        {"appVersion":"1.2","exportDate":"2025-07-01T00:00:00Z","habits":[{
          "id":"IIIIIIII-0000-0000-0000-000000000009",
          "name":"Old Habit","color":"gray","frequency":"daily",
          "activeDays":[],"createdAt":"2024-01-01T00:00:00Z","isArchived":true,
          "currentStreak":0,"longestStreak":30,"entries":[]
        }]}
        """
        let habits = try restore(json)
        XCTAssertTrue(habits.first?.isArchived == true)
    }
}
