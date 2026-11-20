import XCTest
import SwiftData
@testable import HabitTracker

/// HabitStore against an in-memory database: the write paths views use for check-ins.
@MainActor
final class HabitStoreTests: XCTestCase {
    private var store: HabitStore!

    override func setUp() async throws {
        store = try HabitStore.inMemory()
    }

    private func add(_ name: String, intervalMinutes: Int = 0) -> Habit {
        let habit = Habit(name: name, reminderIntervalMinutes: intervalMinutes)
        store.addHabit(habit)
        habit.createdAt = Calendar.current.date(byAdding: .day, value: -30, to: .now)!
        return habit
    }

    private func daysAgo(_ n: Int) -> Date {
        Calendar.current.date(byAdding: .day, value: -n, to: .now)!
    }

    // MARK: Check-ins

    func testToggleCompletesThenUncompletes() {
        let habit = add("Read")
        store.toggleCompletion(for: habit, on: .now)
        XCTAssertTrue(habit.isCompleted(on: .now))
        store.toggleCompletion(for: habit, on: .now)
        XCTAssertFalse(habit.isCompleted(on: .now))
        XCTAssertEqual(habit.entriesOrEmpty.count, 1, "toggling reuses the day's entry")
    }

    func testCompletingASkippedDayClearsTheSkip() {
        let habit = add("Run")
        store.skipDay(for: habit, on: .now, reason: "Rain")
        XCTAssertTrue(habit.isSkipped(on: .now))
        store.toggleCompletion(for: habit, on: .now)
        XCTAssertTrue(habit.isCompleted(on: .now))
        XCTAssertFalse(habit.isSkipped(on: .now))
        XCTAssertNil(habit.entry(for: .now)?.skipReason)
    }

    func testUnskipRestoresTheDay() {
        let habit = add("Meditate")
        store.skipDay(for: habit, on: .now)
        store.unskipDay(for: habit, on: .now)
        XCTAssertFalse(habit.isSkipped(on: .now))
        XCTAssertFalse(habit.isCompleted(on: .now))
    }

    func testIntervalHabitIncrementsThenWrapsToZero() {
        let habit = add("Water", intervalMinutes: 240) // 8 AM-10 PM default window => 4 slots
        let expected = habit.expectedCompletions(on: .now)
        XCTAssertGreaterThan(expected, 1)
        for _ in 0..<expected { store.incrementCompletion(for: habit, on: .now) }
        XCTAssertTrue(habit.isDone(on: .now))
        store.incrementCompletion(for: habit, on: .now)
        XCTAssertEqual(habit.completionCount(on: .now), 0, "tapping past the goal resets the day")
    }

    func testMarkAllCompleteAndReset() {
        let habit = add("Stretch", intervalMinutes: 120)
        store.markAllComplete(for: habit, on: .now)
        XCTAssertTrue(habit.isDone(on: .now))
        store.resetCompletion(for: habit, on: .now)
        XCTAssertFalse(habit.isCompleted(on: .now))
    }

    func testCheckInsDriveTheLiveStreak() {
        let habit = add("Journal")
        for n in [2, 1, 0] { store.toggleCompletion(for: habit, on: daysAgo(n)) }
        XCTAssertEqual(habit.liveStreak.currentStreak, 3)
        store.toggleCompletion(for: habit, on: daysAgo(1))
        XCTAssertEqual(habit.liveStreak.currentStreak, 1)
        XCTAssertEqual(habit.liveStreak.longestStreak, 1)
    }

    // MARK: Duplicates from sync

    func testWritesFoldSameDayDuplicates() {
        let habit = add("Read")
        habit.entries = [HabitEntry(date: .now, isCompleted: false, isSkipped: true),
                         HabitEntry(date: .now, isCompleted: true)]
        store.toggleCompletion(for: habit, on: .now) // completed -> not completed, and folds
        XCTAssertEqual(habit.entriesOrEmpty.count, 1)
    }

    func testMergeDuplicatesKeepsLowestIdAndMovesHistory() {
        let a = add("Walk")
        let b = add("Walk ") // trailing space: same habit after trimming
        store.toggleCompletion(for: a, on: daysAgo(1))
        store.toggleCompletion(for: b, on: daysAgo(2))
        store.toggleCompletion(for: b, on: daysAgo(1)) // same day as a's entry

        let keeperID = [a.id, b.id].min { $0.uuidString < $1.uuidString }!
        store.mergeDuplicates()

        let remaining = store.fetchHabits()
        XCTAssertEqual(remaining.count, 1)
        let keeper = remaining[0]
        XCTAssertEqual(keeper.id, keeperID)
        XCTAssertTrue(keeper.isCompleted(on: daysAgo(1)))
        XCTAssertTrue(keeper.isCompleted(on: daysAgo(2)))
        XCTAssertEqual(keeper.entriesOrEmpty.count, 2, "same-day entries folded into one")
    }

    func testMergeKeepsHabitVisibleIfAnyCopyWasActive() {
        let a = add("Floss")
        let b = add("Floss")
        a.isArchived = true
        b.isArchived = false
        store.mergeDuplicates()
        XCTAssertEqual(store.fetchHabits().first?.isArchived, false)
    }

    func testDifferentNamesAreNotMerged() {
        _ = add("Read")
        _ = add("Run")
        XCTAssertEqual(store.mergeDuplicates(), 0)
        XCTAssertEqual(store.fetchHabits().count, 2)
    }
}

@MainActor
final class MilestoneTests: XCTestCase {
    func testSeventhDayInARowCelebratesOnce() throws {
        let store = try HabitStore.inMemory()
        let defaults = UserDefaults(suiteName: "MilestoneTests-\(UUID().uuidString)")!
        let center = MilestoneCenter(defaults: defaults)
        let habit = Habit(name: "Read")
        store.addHabit(habit)
        habit.createdAt = Calendar.current.date(byAdding: .day, value: -30, to: .now)!
        for n in 1...6 {
            store.toggleCompletion(for: habit, on: Calendar.current.date(byAdding: .day, value: -n, to: .now)!)
        }
        XCTAssertNil(center.checkIn(habit, on: .now), "today isn't checked in yet")

        store.toggleCompletion(for: habit, on: .now)
        XCTAssertEqual(center.checkIn(habit, on: .now)?.days, 7)

        // Unchecking and re-checking the same day doesn't celebrate again.
        store.toggleCompletion(for: habit, on: .now)
        store.toggleCompletion(for: habit, on: .now)
        XCTAssertNil(center.checkIn(habit, on: .now))
    }
}
