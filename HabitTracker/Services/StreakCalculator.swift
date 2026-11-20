import Foundation
import SwiftData

// MARK: - Streak Engine (pure, no SwiftData)

/// Streak rules:
/// - A completed day adds 1, including a bonus completion on a day the habit isn't scheduled.
/// - Skipped days and unscheduled days are neutral: they neither add to nor break a streak.
/// - A scheduled day with no completion and no skip breaks the streak.
/// - Today is never a miss. If today isn't done yet, the streak carries through yesterday.
nonisolated struct StreakEngine {
    nonisolated struct Result: Equatable {
        var current: Int
        var longest: Int
        var lastCompleted: DayKey?
        var streakStart: DayKey?

        static let zero = Result(current: 0, longest: 0, lastCompleted: nil, streakStart: nil)
    }

    var calendar: Calendar = .current

    func compute(
        completed allCompleted: Set<DayKey>,
        skipped: Set<DayKey>,
        today: DayKey,
        isScheduled: (DayKey) -> Bool
    ) -> Result {
        let completed = allCompleted.filter { $0 <= today }
        guard let earliest = completed.min(), let latest = completed.max() else { return .zero }

        func isNeutral(_ day: DayKey) -> Bool {
            skipped.contains(day) || !isScheduled(day)
        }

        // Current streak: walk back from today (or yesterday if today isn't done).
        var current = 0
        var streakStart: DayKey?
        var day = completed.contains(today) ? today : calendar.dayKey(byAdding: -1, to: today)
        while day >= earliest {
            if completed.contains(day) {
                current += 1
                streakStart = day
            } else if !isNeutral(day) {
                break
            }
            day = calendar.dayKey(byAdding: -1, to: day)
        }

        // Longest streak: one forward pass over the whole history.
        var longest = 0
        var run = 0
        day = earliest
        while day <= today {
            if completed.contains(day) {
                run += 1
                longest = max(longest, run)
            } else if !isNeutral(day) && day != today {
                run = 0
            }
            day = calendar.dayKey(byAdding: 1, to: day)
        }

        return Result(
            current: current,
            longest: max(longest, current),
            lastCompleted: latest,
            streakStart: current > 0 ? streakStart : nil
        )
    }
}

// MARK: - Streak Calculator (SwiftData adapter)

/// Computes a habit's streaks from its entries using `StreakEngine`.
@available(iOS 17.0, macOS 14.0, *)
struct StreakCalculator {
    private let calendar: Calendar
    private let engine: StreakEngine

    init(calendar: Calendar = .current) {
        self.calendar = calendar
        self.engine = StreakEngine(calendar: calendar)
    }

    func calculate(for habit: Habit, now: Date = .now) -> (current: Int, longest: Int, lastCompleted: Date?, streakStart: Date?) {
        var completed = Set<DayKey>()
        var skipped = Set<DayKey>()
        for entry in habit.entriesOrEmpty {
            let key = calendar.storedDayKey(for: entry.date)
            if habit.countsAsCompleted(entry) {
                completed.insert(key)
            } else if entry.isSkipped {
                skipped.insert(key)
            }
        }
        // Duplicate same-day entries (e.g. from sync) never let a skip hide a completion.
        skipped.subtract(completed)

        let result = engine.compute(
            completed: completed,
            skipped: skipped,
            today: calendar.dayKey(for: now),
            isScheduled: { habit.isScheduledWeekday(calendar.noon(of: $0), calendar: calendar) }
        )
        return (
            result.current,
            result.longest,
            result.lastCompleted.map { calendar.startOfDay(of: $0) },
            result.streakStart.map { calendar.startOfDay(of: $0) }
        )
    }
}

// MARK: - Live streaks (computed when shown)

/// Streak values for display, computed from entry history.
///
/// Field names match the legacy `Streak` model, which stays in the schema for CloudKit but isn't
/// written.
struct HabitStreak: Equatable {
    var currentStreak: Int
    var longestStreak: Int
    var lastCompletedDate: Date?
    var streakStartDate: Date?
}

/// Memoizes streaks per habit. The key is cheap to compute (no calendar math) and changes whenever
/// an entry is added, edited or synced, the schedule changes, or the day rolls over.
@available(iOS 17.0, macOS 14.0, *)
@MainActor
final class StreakCache {
    static let shared = StreakCache()
    private var cache: [PersistentIdentifier: (key: Int, value: HabitStreak)] = [:]

    func streak(for habit: Habit, now: Date = .now) -> HabitStreak {
        let entries = habit.entriesOrEmpty
        var hasher = Hasher()
        hasher.combine(entries.count)
        hasher.combine(entries.lazy.map(\.updatedAt).max())
        hasher.combine(habit.frequencyRaw)
        hasher.combine(habit.activeDaysRaw.sorted())
        hasher.combine(habit.reminderIntervalMinutes)
        hasher.combine(Calendar.current.dayKey(for: now))
        let key = hasher.finalize()

        let id = habit.persistentModelID
        if let hit = cache[id], hit.key == key { return hit.value }
        let r = StreakCalculator().calculate(for: habit, now: now)
        let value = HabitStreak(currentStreak: r.current, longestStreak: r.longest,
                                lastCompletedDate: r.lastCompleted, streakStartDate: r.streakStart)
        cache[id] = (key, value)
        return value
    }
}

@available(iOS 17.0, macOS 14.0, *)
extension Habit {
    @MainActor
    var liveStreak: HabitStreak { StreakCache.shared.streak(for: self) }
    /// Nil until the habit has been completed at least once.
    @MainActor
    var streakIfStarted: HabitStreak? {
        let s = liveStreak
        return s.longestStreak > 0 ? s : nil
    }
}
