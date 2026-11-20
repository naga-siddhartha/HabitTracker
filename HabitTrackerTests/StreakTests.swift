import XCTest
import SwiftData
@testable import HabitTracker

// MARK: - Helpers

private let newYork: Calendar = {
    var cal = Calendar(identifier: .gregorian)
    cal.timeZone = TimeZone(identifier: "America/New_York")!
    return cal
}()

/// Day keys counted back from `today`: `days(today, 0, 1, 2)` = today, yesterday, two days ago.
private func days(_ today: DayKey, _ offsets: Int...) -> Set<DayKey> {
    Set(offsets.map { newYork.dayKey(byAdding: -$0, to: today) })
}

// Thursday 19 Nov 2026
private let thursday = DayKey(year: 2026, month: 11, day: 19)

// MARK: - Streak engine

@MainActor
final class StreakEngineTests: XCTestCase {
    private let engine = StreakEngine(calendar: newYork)
    private let everyDay: (DayKey) -> Bool = { _ in true }

    func testNoCompletionsIsZero() {
        let r = engine.compute(completed: [], skipped: [], today: thursday, isScheduled: everyDay)
        XCTAssertEqual(r, .zero)
    }

    func testRunEndingToday() {
        let r = engine.compute(completed: days(thursday, 0, 1, 2), skipped: [], today: thursday, isScheduled: everyDay)
        XCTAssertEqual(r.current, 3)
        XCTAssertEqual(r.longest, 3)
        XCTAssertEqual(r.streakStart, newYork.dayKey(byAdding: -2, to: thursday))
    }

    /// Regression: the old calculator showed 2 here until today was checked off.
    func testRunEndingYesterdayIsStillAlive() {
        let r = engine.compute(completed: days(thursday, 1, 2, 3), skipped: [], today: thursday, isScheduled: everyDay)
        XCTAssertEqual(r.current, 3)
    }

    func testMissedYesterdayBreaksStreak() {
        let r = engine.compute(completed: days(thursday, 2, 3, 4), skipped: [], today: thursday, isScheduled: everyDay)
        XCTAssertEqual(r.current, 0)
        XCTAssertEqual(r.longest, 3)
        XCTAssertNil(r.streakStart)
    }

    func testSkippedDayIsNeutral() {
        let r = engine.compute(completed: days(thursday, 0, 2), skipped: days(thursday, 1), today: thursday, isScheduled: everyDay)
        XCTAssertEqual(r.current, 2)
    }

    func testSkippedTodayKeepsStreak() {
        let r = engine.compute(completed: days(thursday, 1, 2), skipped: days(thursday, 0), today: thursday, isScheduled: everyDay)
        XCTAssertEqual(r.current, 2)
    }

    /// Regression: Mon/Wed/Fri habits used to lose their streak on every off day.
    func testWeeklyScheduleIgnoresOffDays() {
        let mwf: Set<Int> = [2, 4, 6] // Calendar weekday numbers
        let isScheduled: (DayKey) -> Bool = { mwf.contains(newYork.component(.weekday, from: newYork.noon(of: $0))) }
        // Thu 19 (today, off day). Completed Wed 18, Mon 16, Fri 13, Wed 11.
        let r = engine.compute(completed: days(thursday, 1, 3, 6, 8), skipped: [], today: thursday, isScheduled: isScheduled)
        XCTAssertEqual(r.current, 4)
    }

    func testWeeklyMissedScheduledDayBreaks() {
        let mwf: Set<Int> = [2, 4, 6]
        let isScheduled: (DayKey) -> Bool = { mwf.contains(newYork.component(.weekday, from: newYork.noon(of: $0))) }
        // Completed Wed 18 and Fri 13, missed Mon 16.
        let r = engine.compute(completed: days(thursday, 1, 6), skipped: [], today: thursday, isScheduled: isScheduled)
        XCTAssertEqual(r.current, 1)
        XCTAssertEqual(r.longest, 1)
    }

    func testBonusCompletionOnOffDayCounts() {
        let weekdaysOnly: (DayKey) -> Bool = { ![1, 7].contains(newYork.component(.weekday, from: newYork.noon(of: $0))) }
        // Sat 14 is an off day but was done anyway; Fri 13 and Mon 16 also done; Tue-Thu done.
        let r = engine.compute(completed: days(thursday, 0, 1, 2, 3, 5, 6), skipped: [], today: thursday, isScheduled: weekdaysOnly)
        XCTAssertEqual(r.current, 6)
    }

    /// Regression: longest streak used to be max(stored, current) and could never go down.
    func testLongestIsRecomputedFromHistory() {
        let r = engine.compute(completed: days(thursday, 0, 1, 5, 6, 7, 8, 9), skipped: [], today: thursday, isScheduled: everyDay)
        XCTAssertEqual(r.current, 2)
        XCTAssertEqual(r.longest, 5)

        let unchecked = engine.compute(completed: days(thursday, 0, 1, 5, 6, 8, 9), skipped: [], today: thursday, isScheduled: everyDay)
        XCTAssertEqual(unchecked.longest, 2)
    }

    func testFutureCompletionsAreIgnored() {
        let tomorrow = newYork.dayKey(byAdding: 1, to: thursday)
        let r = engine.compute(completed: days(thursday, 0).union([tomorrow]), skipped: [], today: thursday, isScheduled: everyDay)
        XCTAssertEqual(r.current, 1)
        XCTAssertEqual(r.lastCompleted, thursday)
    }

    func testRunAcrossDaylightSavingEnd() {
        // US DST ended Sunday 1 Nov 2026.
        let today = DayKey(year: 2026, month: 11, day: 3)
        let r = engine.compute(completed: days(today, 0, 1, 2, 3, 4), skipped: [], today: today, isScheduled: everyDay)
        XCTAssertEqual(r.current, 5)
    }
}

// MARK: - Day keys

final class DayKeyTests: XCTestCase {
    func testStoredMidnightSurvivesWestwardTravel() {
        // Entry saved at local midnight in New York, read later in Los Angeles (9 PM the day before).
        let midnightNY = newYork.startOfDay(of: thursday)
        var la = Calendar(identifier: .gregorian)
        la.timeZone = TimeZone(identifier: "America/Los_Angeles")!
        XCTAssertEqual(la.dayKey(for: midnightNY), DayKey(year: 2026, month: 11, day: 18))
        XCTAssertEqual(la.storedDayKey(for: midnightNY), thursday)
    }

    func testStoredMidnightSurvivesEastwardTravel() {
        var london = Calendar(identifier: .gregorian)
        london.timeZone = TimeZone(identifier: "Europe/London")!
        XCTAssertEqual(london.storedDayKey(for: newYork.startOfDay(of: thursday)), thursday)
    }

    func testDayArithmeticAcrossMonthAndYear() {
        XCTAssertEqual(newYork.dayKey(byAdding: 1, to: DayKey(year: 2026, month: 12, day: 31)), DayKey(year: 2027, month: 1, day: 1))
        XCTAssertEqual(newYork.dayKey(byAdding: -1, to: DayKey(year: 2028, month: 3, day: 1)), DayKey(year: 2028, month: 2, day: 29))
    }
}

// MARK: - Habit + SwiftData

@MainActor
final class HabitStreakIntegrationTests: XCTestCase {
    private var container: ModelContainer!
    private var context: ModelContext!

    override func setUp() async throws {
        container = try ModelContainer(
            for: Habit.self, HabitEntry.self, Streak.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        context = container.mainContext
    }

    private func date(_ offset: Int, from now: Date = .now) -> Date {
        Calendar.current.date(byAdding: .day, value: -offset, to: now)!
    }

    private func makeHabit(_ habit: Habit, completedDaysAgo offsets: [Int]) -> Habit {
        context.insert(habit)
        habit.createdAt = date(30)
        habit.entries = offsets.map { HabitEntry(date: date($0)) }
        return habit
    }

    func testDuplicateEntriesPreferTheCompletedOne() {
        let habit = makeHabit(Habit(name: "Read"), completedDaysAgo: [])
        let skipped = HabitEntry(date: .now, isCompleted: false, isSkipped: true)
        let done = HabitEntry(date: .now, isCompleted: true)
        habit.entries = [skipped, done]
        XCTAssertTrue(habit.isCompleted(on: .now))
        XCTAssertFalse(habit.isSkipped(on: .now))
        XCTAssertTrue(habit.entry(for: .now) === done)
    }

    func testDayIndexSeesAddedEntriesAndEdits() {
        let habit = makeHabit(Habit(name: "Stretch"), completedDaysAgo: [2])
        XCTAssertTrue(habit.isCompleted(on: date(2)))
        XCTAssertFalse(habit.isCompleted(on: date(1)))

        // Adding an entry changes the count, so the index rebuilds.
        habit.entries = habit.entriesOrEmpty + [HabitEntry(date: date(1))]
        XCTAssertTrue(habit.isCompleted(on: date(1)))

        // Editing an existing entry is visible without a rebuild.
        habit.entry(for: date(1))?.isCompleted = false
        XCTAssertFalse(habit.isCompleted(on: date(1)))
    }

    func testLiveStreakUpdatesAfterNewCheckIn() {
        let habit = makeHabit(Habit(name: "Journal"), completedDaysAgo: [1, 2])
        XCTAssertEqual(habit.liveStreak.currentStreak, 2)
        habit.entries = habit.entriesOrEmpty + [HabitEntry(date: .now)]
        XCTAssertEqual(habit.liveStreak.currentStreak, 3)
    }

    func testIntervalHabitWithProgressCountsTowardStreak() {
        let habit = makeHabit(Habit(name: "Water", reminderIntervalMinutes: 120), completedDaysAgo: [])
        let partial = HabitEntry(date: date(1), isCompleted: false)
        partial.completionCount = 2
        habit.entries = [partial, HabitEntry(date: date(2))]
        XCTAssertTrue(habit.isCompleted(on: date(1)))
        XCTAssertEqual(StreakCalculator().calculate(for: habit).current, 2)
    }

    func testDailyStreakThroughYesterday() {
        let habit = makeHabit(Habit(name: "Walk"), completedDaysAgo: [1, 2, 3])
        XCTAssertEqual(StreakCalculator().calculate(for: habit).current, 3)
    }

    func testWeeklyHabitStreakUsesSchedule() {
        // Schedule = the weekdays of 1, 3 and 5 days ago; every scheduled day done.
        let cal = Calendar.current
        let scheduled = Set([1, 3, 5].compactMap { Weekday(rawValue: cal.component(.weekday, from: date($0))) })
        let habit = makeHabit(Habit(name: "Gym", frequency: .weekly, activeDays: scheduled), completedDaysAgo: [1, 3, 5])
        XCTAssertEqual(StreakCalculator().calculate(for: habit).current, 3)
    }
}

// MARK: - Reminders

@MainActor
final class NotificationPlanTests: XCTestCase {
    private func habit(_ name: String, times: Int = 0, intervalMinutes: Int = 0, frequency: HabitFrequency = .daily, days: Set<Weekday> = []) -> NotificationHabit {
        let start = Calendar.current.date(bySettingHour: 6, minute: 0, second: 0, of: .now)!
        let reminderTimes = intervalMinutes > 0 ? [start] : (0..<times).map { start.addingTimeInterval(Double($0) * 3600) }
        return NotificationHabit(
            id: UUID(), name: name, frequency: frequency,
            reminderTimes: reminderTimes, reminderNames: [], reminderSounds: [],
            reminderIntervalMinutes: intervalMinutes, reminderEndTime: nil, activeDays: days
        )
    }

    func testStaysUnderIOSLimitAndKeepsFixedTimeReminders() {
        let fixed = habit("Meds", times: 2)
        let intervals = (0..<5).map { habit("Water \($0)", intervalMinutes: 30) }
        let requests = NotificationService.buildRequests(for: intervals + [fixed])
        XCTAssertEqual(requests.count, NotificationService.maxPendingRequests)
        let fixedIds = requests.filter { $0.identifier.hasPrefix(fixed.id.uuidString) }
        XCTAssertEqual(fixedIds.count, 2)
        // Round-robin: every interval habit keeps its first slot.
        for h in intervals {
            XCTAssertTrue(requests.contains { $0.identifier == "\(h.id.uuidString)-interval-0" })
        }
    }

    func testWeeklyAllDaysUsesOneDailyTrigger() {
        let everyDay = habit("Stretch", times: 1, frequency: .weekly, days: Set(Weekday.allCases))
        XCTAssertEqual(NotificationService.buildRequests(for: [everyDay]).count, 1)
    }

    func testWeeklySubsetSchedulesEachDay() {
        let mwf = habit("Gym", times: 1, frequency: .weekly, days: [.monday, .wednesday, .friday])
        XCTAssertEqual(NotificationService.buildRequests(for: [mwf]).count, 3)
    }
}
