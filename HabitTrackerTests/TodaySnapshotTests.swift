import XCTest
import SwiftData
@testable import HabitTracker

@MainActor
final class TodaySnapshotTests: XCTestCase {
    private var store: HabitStore!
    private let calendar = Calendar.current

    override func setUp() async throws {
        store = try HabitStore.inMemory()
    }

    /// Fixed "now": today at 12:00.
    private var noon: Date { calendar.date(bySettingHour: 12, minute: 0, second: 0, of: .now)! }
    private func at(_ hour: Int) -> Date { calendar.date(bySettingHour: hour, minute: 0, second: 0, of: .now)! }

    private func add(_ name: String, reminderHour: Int? = nil, archived: Bool = false,
                     weeklyOn days: Set<Weekday>? = nil) -> Habit {
        let habit = Habit(
            name: name,
            frequency: days == nil ? .daily : .weekly,
            reminderTimes: reminderHour.map { [at($0)] } ?? [],
            activeDays: days ?? []
        )
        store.addHabit(habit)
        habit.createdAt = calendar.date(byAdding: .day, value: -7, to: .now)!
        habit.isArchived = archived
        return habit
    }

    func testSplitsDueNowLaterDoneAndSkipped() {
        let noReminder = add("Read")
        let morning = add("Vitamins", reminderHour: 8)
        let evening = add("Stretch", reminderHour: 20)
        let done = add("Walk")
        let skipped = add("Run")
        store.toggleCompletion(for: done, on: noon)
        store.skipDay(for: skipped, on: noon)

        let s = TodaySnapshot(habits: store.fetchHabits(), now: noon)
        XCTAssertEqual(s.dueNow.map(\.name), [noReminder.name, morning.name])
        XCTAssertEqual(s.later.map(\.name), [evening.name])
        XCTAssertEqual(s.completed.map(\.name), [done.name])
        XCTAssertEqual(s.skipped.map(\.name), [skipped.name])
        XCTAssertEqual(s.doneCount, 1)
        XCTAssertEqual(s.actionableCount, 4, "5 due, 1 skipped")
        XCTAssertEqual(s.progress, 0.25, accuracy: 0.0001)
    }

    /// A bonus completion of a habit not due today counts as done but not toward progress.
    func testBonusCompletionDoesNotInflateProgress() {
        let today = Weekday(rawValue: calendar.component(.weekday, from: noon))!
        let otherDay = Weekday.allCases.first { $0 != today }!
        let due = add("Read")
        let notDue = add("Gym", weeklyOn: [otherDay])
        store.toggleCompletion(for: due, on: noon)
        store.toggleCompletion(for: notDue, on: noon)

        let s = TodaySnapshot(habits: store.fetchHabits(), now: noon)
        XCTAssertEqual(s.completed.count, 2, "bonus completion still shows as done")
        XCTAssertEqual(s.doneCount, 1)
        XCTAssertEqual(s.actionableCount, 1)
        XCTAssertEqual(s.progress, 1)
    }

    func testArchivedHabitsAreHidden() {
        _ = add("Old habit", archived: true)
        let s = TodaySnapshot(habits: store.fetchHabits(), now: noon)
        XCTAssertTrue(s.isEmpty)
        XCTAssertEqual(s.progress, 0)
    }

    func testAllSkippedMeansNothingActionable() {
        let a = add("Read")
        store.skipDay(for: a, on: noon)
        let s = TodaySnapshot(habits: store.fetchHabits(), now: noon)
        XCTAssertEqual(s.actionableCount, 0)
        XCTAssertEqual(s.progress, 0)
        XCTAssertFalse(s.isEmpty)
    }
}

@MainActor
final class PerfectDayStreakTests: XCTestCase {
    private var store: HabitStore!
    private let calendar = Calendar.current

    override func setUp() async throws {
        store = try HabitStore.inMemory()
    }

    private func daysAgo(_ n: Int) -> Date {
        calendar.date(byAdding: .day, value: -n, to: calendar.date(bySettingHour: 12, minute: 0, second: 0, of: .now)!)!
    }

    private func add(_ name: String) -> Habit {
        let habit = Habit(name: name)
        store.addHabit(habit)
        habit.createdAt = daysAgo(10)
        return habit
    }

    func testCountsBackFromYesterdayUntilTodayIsDone() {
        let a = add("Read")
        let b = add("Walk")
        for n in 1...3 { store.toggleCompletion(for: a, on: daysAgo(n)); store.toggleCompletion(for: b, on: daysAgo(n)) }
        store.toggleCompletion(for: a, on: daysAgo(4)) // day 4 only half done

        XCTAssertEqual(TodaySnapshot.perfectDayStreak(habits: store.fetchHabits(), now: daysAgo(0)), 3)
        store.toggleCompletion(for: a, on: daysAgo(0))
        store.toggleCompletion(for: b, on: daysAgo(0))
        XCTAssertEqual(TodaySnapshot.perfectDayStreak(habits: store.fetchHabits(), now: daysAgo(0)), 4)
    }

    func testSkippedHabitDoesNotBreakAPerfectDay() {
        let a = add("Read")
        let b = add("Run")
        store.toggleCompletion(for: a, on: daysAgo(1))
        store.skipDay(for: b, on: daysAgo(1))
        XCTAssertEqual(TodaySnapshot.perfectDayStreak(habits: store.fetchHabits(), now: daysAgo(0)), 1)
    }
}
