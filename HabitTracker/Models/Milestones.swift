import Foundation
import Observation

/// A streak milestone reached by a check-in, shown as a celebration banner.
struct MilestoneEvent: Identifiable, Equatable {
    let id = UUID()
    let habitName: String
    let emoji: String?
    let days: Int
}

/// Detects streak milestones on check-in and holds the one to celebrate.
@available(iOS 17.0, macOS 14.0, *)
@MainActor
@Observable
final class MilestoneCenter {
    static let shared = MilestoneCenter()

    /// Streak lengths worth celebrating.
    static let milestoneDays: Set<Int> = [7, 14, 30, 50, 100, 200, 365]

    /// The milestone to show now; the banner clears it.
    var current: MilestoneEvent?

    @ObservationIgnored private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    /// Celebrates when today's check-in lands the habit's streak on a milestone.
    ///
    /// Each milestone fires once per streak run, so unchecking and re-checking doesn't repeat it.
    @discardableResult
    func checkIn(_ habit: Habit, on date: Date) -> MilestoneEvent? {
        guard Calendar.current.isDateInToday(date), habit.isCompleted(on: date) else { return nil }
        let streak = habit.liveStreak
        guard Self.milestoneDays.contains(streak.currentStreak), let start = streak.streakStartDate else { return nil }

        let runKey = Calendar.current.dayKey(for: start).description
        let key = "milestone.\(habit.id.uuidString).\(streak.currentStreak).\(runKey)"
        guard !defaults.bool(forKey: key) else { return nil }
        defaults.set(true, forKey: key)

        let event = MilestoneEvent(habitName: habit.name, emoji: habit.emoji, days: streak.currentStreak)
        current = event
        return event
    }
}
