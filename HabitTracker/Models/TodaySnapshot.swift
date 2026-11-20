import Foundation

/// What Home shows for one moment: which habits are due now, due later, done or skipped, and the
/// progress numbers. Plain logic with no SwiftUI, so it's unit tested.
@available(iOS 17.0, macOS 14.0, *)
@MainActor
struct TodaySnapshot {
    /// Due today, not done or skipped, and due by now (no reminder time, or its time has passed).
    let dueNow: [Habit]
    /// Due today, not done or skipped, first reminder later today.
    let later: [Habit]
    /// Fully done today, including a bonus completion on a day it isn't scheduled.
    let completed: [Habit]
    /// Due today and skipped.
    let skipped: [Habit]
    /// Every non-archived habit scheduled today.
    let dueToday: [Habit]

    /// Done among the habits due today.
    let doneCount: Int
    /// Due today minus skipped: the denominator for progress.
    let actionableCount: Int

    var progress: Double {
        actionableCount == 0 ? 0 : min(1, Double(doneCount) / Double(actionableCount))
    }

    /// Nothing due and nothing done: Home shows its empty state.
    var isEmpty: Bool { dueToday.isEmpty && completed.isEmpty }

    /// Whether every habit due today (and not skipped) is done.
    var isPerfectDay: Bool { actionableCount > 0 && doneCount >= actionableCount }

    /// Consecutive perfect days ending today, or yesterday if today isn't finished yet.
    /// Days with nothing due neither count nor break the run.
    static func perfectDayStreak(habits: [Habit], now: Date = .now, calendar: Calendar = .current) -> Int {
        let earliest = habits.map(\.createdAt).min() ?? now
        var day = now
        if !TodaySnapshot(habits: habits, now: day, calendar: calendar).isPerfectDay {
            day = calendar.date(byAdding: .day, value: -1, to: day) ?? day
        }
        var streak = 0
        for _ in 0..<366 {
            guard calendar.startOfDay(for: day) >= calendar.startOfDay(for: earliest) else { break }
            let snapshot = TodaySnapshot(habits: habits, now: calendar.date(bySettingHour: 23, minute: 59, second: 0, of: day) ?? day, calendar: calendar)
            if snapshot.isPerfectDay {
                streak += 1
            } else if snapshot.actionableCount > 0 {
                break
            }
            day = calendar.date(byAdding: .day, value: -1, to: day) ?? day
        }
        return streak
    }

    init(habits: [Habit], now: Date = .now, calendar: Calendar = .current) {
        let visible = habits.filter { !$0.isArchived }
        let byName: (Habit, Habit) -> Bool = {
            $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
        }

        let due = visible.filter { $0.isActive(on: now) }
        let done = visible.filter { $0.isDone(on: now) }
        let doneIDs = Set(done.map(\.id))
        let skipped = due.filter { !doneIDs.contains($0.id) && $0.isSkipped(on: now) }
        let skippedIDs = Set(skipped.map(\.id))
        let pending = due.filter { !doneIDs.contains($0.id) && !skippedIDs.contains($0.id) }

        func firstReminderToday(_ habit: Habit) -> Date? {
            guard let first = habit.reminderTimes.first else { return nil }
            let c = calendar.dateComponents([.hour, .minute], from: first)
            return calendar.date(bySettingHour: c.hour ?? 0, minute: c.minute ?? 0, second: 0, of: now)
        }

        dueToday = due.sorted(by: byName)
        later = pending.filter { firstReminderToday($0).map { now < $0 } ?? false }.sorted(by: byName)
        let laterIDs = Set(later.map(\.id))
        dueNow = pending.filter { !laterIDs.contains($0.id) }.sorted(by: byName)
        completed = done.sorted(by: byName)
        self.skipped = skipped.sorted(by: byName)
        doneCount = due.filter { doneIDs.contains($0.id) }.count
        actionableCount = due.count - skipped.count
    }
}
