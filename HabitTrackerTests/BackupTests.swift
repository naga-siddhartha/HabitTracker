import XCTest
import SwiftData
@testable import HabitTracker

@MainActor
final class BackupRoundTripTests: XCTestCase {
    private func makeContext() throws -> ModelContext {
        let container = try ModelContainer(
            for: Habit.self, HabitEntry.self, Streak.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        return ModelContext(container)
    }

    func testBackupKeepsRemindersEmojiAndIntervalProgress() throws {
        let source = try makeContext()
        let start = Calendar.current.date(bySettingHour: 8, minute: 0, second: 0, of: .now)!
        let end = Calendar.current.date(bySettingHour: 20, minute: 0, second: 0, of: .now)!
        let habit = Habit(
            name: "Water", emoji: "💧", color: .custom,
            reminderTimes: [start], reminderNames: ["Drink"], reminderSounds: [.chime],
            reminderIntervalMinutes: 120, reminderEndTime: end
        )
        habit.customColorHex = "#3366FF"
        source.insert(habit)
        let entry = HabitEntry(date: .now, isCompleted: true)
        entry.completionCount = 3
        habit.entries = [entry]

        let data = try XCTUnwrap(ExportService.exportToJSON(habits: [habit]))
        let parsed = try ImportService.parseExportData(data)

        let target = try makeContext()
        try ImportService.replaceAllAndRestore(from: parsed, context: target)
        let restored = try XCTUnwrap(target.fetch(FetchDescriptor<Habit>()).first)

        XCTAssertEqual(restored.id, habit.id)
        XCTAssertEqual(restored.emoji, "💧")
        XCTAssertEqual(restored.customColorHex, "#3366FF")
        XCTAssertEqual(restored.reminderNames, ["Drink"])
        XCTAssertEqual(restored.sounds, [.chime])
        XCTAssertEqual(restored.reminderIntervalMinutes, 120)
        XCTAssertNotNil(restored.reminderEndTime)
        XCTAssertEqual(restored.entriesOrEmpty.first?.completionCount, 3)
    }

    func testOldBackupWithoutNewFieldsStillRestores() throws {
        let json = """
        {"appVersion":"1.2","exportDate":"2026-01-01T00:00:00Z","habits":[{
          "id":"0F8C3E4A-1111-4222-8333-944455556666","name":"Read","color":"blue","frequency":"daily",
          "activeDays":[],"createdAt":"2025-12-01T00:00:00Z","isArchived":false,
          "currentStreak":0,"longestStreak":0,
          "entries":[{"date":"2025-12-31T05:00:00Z","isCompleted":true,"isSkipped":false}]
        }]}
        """
        let parsed = try ImportService.parseExportData(Data(json.utf8))
        let context = try makeContext()
        try ImportService.replaceAllAndRestore(from: parsed, context: context)
        let restored = try XCTUnwrap(context.fetch(FetchDescriptor<Habit>()).first)
        XCTAssertEqual(restored.name, "Read")
        XCTAssertEqual(restored.reminderIntervalMinutes, 0)
        XCTAssertEqual(restored.entriesOrEmpty.count, 1)
    }
}
