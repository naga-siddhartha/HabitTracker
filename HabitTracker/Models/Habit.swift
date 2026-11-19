import Foundation
import SwiftData
import SwiftUI

// MARK: - Habit

@available(iOS 17.0, macOS 14.0, *)
@Model
final class Habit {
    @Attribute(.preserveValueOnDeletion) var id: UUID = UUID()
    var name: String = ""
    var habitDescription: String?
    var iconName: String?
    var emoji: String?
    var colorName: String = HabitColor.blue.rawValue
    var customColorHex: String?
    var frequencyRaw: String = HabitFrequency.daily.rawValue
    var reminderTimes: [Date] = []
    var reminderNames: [String] = []
    var reminderSounds: [String] = []
    /// When greater than zero, schedule a repeating reminder every N minutes (used for "every few hours" habits).
    var reminderIntervalMinutes: Int = 0
    /// End time for repeating reminders (stop sending after this time). Nil means remind all day.
    var reminderEndTime: Date?
    var activeDaysRaw: [Int] = []
    var createdAt: Date = Date()
    var updatedAt: Date = Date()
    var isArchived: Bool = false
    /// When non-nil, habit is associated with a signed-in user (sync).
    var userId: String?
    
    /// CloudKit requires relationships to be optional. Use `entriesOrEmpty` for reads to avoid optional handling.
    @Relationship(deleteRule: .cascade, inverse: \HabitEntry.habit)
    var entries: [HabitEntry]? = []
    
    @Relationship(deleteRule: .cascade, inverse: \Streak.habit)
    var streak: Streak?
    
    init(
        name: String,
        description: String? = nil,
        iconName: String? = nil,
        emoji: String? = nil,
        color: HabitColor = .blue,
        frequency: HabitFrequency = .daily,
        reminderTimes: [Date] = [],
        reminderNames: [String] = [],
        reminderSounds: [ReminderSound] = [],
        activeDays: Set<Weekday> = [],
        reminderIntervalMinutes: Int = 0,
        reminderEndTime: Date? = nil
    ) {
        self.id = UUID()
        self.name = name
        self.habitDescription = description
        self.iconName = iconName
        self.emoji = emoji
        self.colorName = color.rawValue
        self.frequencyRaw = frequency.rawValue
        self.reminderTimes = reminderTimes
        self.reminderNames = reminderNames
        self.reminderSounds = reminderSounds.map(\.rawValue)
        self.activeDaysRaw = activeDays.map(\.rawValue)
        self.reminderIntervalMinutes = reminderIntervalMinutes
        self.reminderEndTime = reminderEndTime
        self.createdAt = .now
        self.updatedAt = .now
        self.isArchived = false
        self.userId = nil
    }
}

// MARK: - Computed Properties

@available(iOS 17.0, macOS 14.0, *)
extension Habit {
    /// Non-optional view of entries for CloudKit compatibility (relationship must be optional).
    var entriesOrEmpty: [HabitEntry] { entries ?? [] }

    var color: HabitColor {
        get { HabitColor(rawValue: colorName) ?? .blue }
        set { colorName = newValue.rawValue }
    }

    /// Resolved color for display: custom hex when color is custom, otherwise the preset color.
    var displayColor: Color {
        if colorName == HabitColor.custom.rawValue, let hex = customColorHex, let c = Color(hex: hex) {
            return c
        }
        return color.color
    }

    var frequency: HabitFrequency {
        get { HabitFrequency(rawValue: frequencyRaw) ?? .daily }
        set { frequencyRaw = newValue.rawValue }
    }
    
    var activeDays: Set<Weekday> {
        get { Set(activeDaysRaw.compactMap { Weekday(rawValue: $0) }) }
        set { activeDaysRaw = newValue.map(\.rawValue) }
    }
    
    var sounds: [ReminderSound] {
        get { reminderSounds.compactMap { ReminderSound(rawValue: $0) } }
        set { reminderSounds = newValue.map(\.rawValue) }
    }

    /// Human-readable schedule description for display (e.g., "Every 2h · 8 AM – 6 PM")
    var scheduleDescription: String? {
        guard reminderIntervalMinutes > 0 else {
            if let first = reminderTimes.first {
                return first.formatted(date: .omitted, time: .shortened)
            }
            return nil
        }
        let intervalText: String
        if reminderIntervalMinutes < 60 {
            intervalText = "Every \(reminderIntervalMinutes)m"
        } else if reminderIntervalMinutes % 60 == 0 {
            let hours = reminderIntervalMinutes / 60
            intervalText = "Every \(hours)h"
        } else {
            let hours = reminderIntervalMinutes / 60
            let mins = reminderIntervalMinutes % 60
            intervalText = "Every \(hours)h \(mins)m"
        }
        guard let startTime = reminderTimes.first else { return intervalText }
        let startText = startTime.formatted(date: .omitted, time: .shortened)
        if let endTime = reminderEndTime {
            let endText = endTime.formatted(date: .omitted, time: .shortened)
            return "\(intervalText) · \(startText) – \(endText)"
        }
        return "\(intervalText) from \(startText)"
    }
}

// MARK: - Status Checks

@available(iOS 17.0, macOS 14.0, *)
extension Habit {
    func isActive(on date: Date) -> Bool {
        let cal = Calendar.current
        let createdDay = cal.startOfDay(for: createdAt)
        let checkDay = cal.startOfDay(for: date)
        guard checkDay >= createdDay else { return false }
        return isScheduledWeekday(date, calendar: cal)
    }

    /// Whether the habit's schedule includes this weekday, ignoring the creation date.
    /// Streaks use this so imported or backfilled history is judged by the same schedule.
    func isScheduledWeekday(_ date: Date, calendar: Calendar = .current) -> Bool {
        guard frequency == .weekly, !activeDays.isEmpty else { return true }
        guard let weekday = Weekday(rawValue: calendar.component(.weekday, from: date)) else { return false }
        return activeDays.contains(weekday)
    }

    /// Single definition of "completed" for an entry. Interval habits count any progress.
    func countsAsCompleted(_ entry: HabitEntry) -> Bool {
        if reminderIntervalMinutes > 0 { return entry.completionCount > 0 || entry.isCompleted }
        return entry.isCompleted
    }

    func isCompleted(on date: Date) -> Bool {
        guard let e = entry(for: date) else { return false }
        return countsAsCompleted(e)
    }

    func isSkipped(on date: Date) -> Bool {
        guard let e = entry(for: date) else { return false }
        return e.isSkipped && !countsAsCompleted(e)
    }

    /// The entry for a day. If sync left several entries for the same day, returns the most
    /// complete one (most progress, then most recently updated) so results are deterministic.
    func entry(for date: Date) -> HabitEntry? {
        entries(on: date).max(by: { HabitEntry.isLessComplete($0, than: $1, countsAsCompleted: countsAsCompleted) })
    }

    /// All entries recorded for the same day (normally one; more only after sync conflicts).
    func entries(on date: Date) -> [HabitEntry] {
        let cal = Calendar.current
        let key = cal.dayKey(for: date)
        // Cheap time-window check first so calendar math only runs for nearby entries.
        let center = cal.noon(of: key).timeIntervalSinceReferenceDate
        let window: TimeInterval = 26 * 3600
        return entriesOrEmpty.filter {
            abs($0.date.timeIntervalSinceReferenceDate - center) < window
                && cal.storedDayKey(for: $0.date) == key
        }
    }

    /// How many times this habit was completed on a given day.
    func completionCount(on date: Date) -> Int {
        guard let e = entry(for: date) else { return 0 }
        if reminderIntervalMinutes > 0 {
            // Legacy entries (isCompleted=true, completionCount=0): treat as fully completed
            return e.completionCount > 0 ? e.completionCount : (e.isCompleted ? expectedCompletions(on: date) : 0)
        }
        return e.isCompleted ? 1 : 0
    }

    /// Total number of expected completions for this habit on a given day.
    func expectedCompletions(on date: Date) -> Int {
        guard reminderIntervalMinutes > 0 else { return 1 }
        let cal = Calendar.current
        // If no start time configured, default to 8 AM
        let startMins: Int
        if let start = reminderTimes.first {
            startMins = cal.component(.hour, from: start) * 60 + cal.component(.minute, from: start)
        } else {
            startMins = 8 * 60
        }
        // If no end time configured, default to 10 PM (22:00)
        let endMins: Int
        if let end = reminderEndTime {
            endMins = cal.component(.hour, from: end) * 60 + cal.component(.minute, from: end)
        } else {
            endMins = 22 * 60
        }
        guard endMins > startMins else { return 1 }
        return max(1, (endMins - startMins) / reminderIntervalMinutes + 1)
    }

    /// Whether all expected completions for the day are done.
    func isFullyCompleted(on date: Date) -> Bool {
        completionCount(on: date) >= expectedCompletions(on: date)
    }

    /// The display-level "done" state used for home page categorization and visual completion.
    /// For repeating habits: requires ALL expected instances done.
    /// For single-completion habits: same as isCompleted.
    func isDone(on date: Date) -> Bool {
        reminderIntervalMinutes > 0 ? isFullyCompleted(on: date) : isCompleted(on: date)
    }
}

// MARK: - Habit Entry

@available(iOS 17.0, macOS 14.0, *)
@Model
final class HabitEntry {
    @Attribute(.preserveValueOnDeletion) var id: UUID = UUID()
    var date: Date = Date()
    var isCompleted: Bool = false
    var isSkipped: Bool = false
    var skipReason: String?
    var updatedAt: Date = Date()
    var habit: Habit?
    /// When non-nil, entry belongs to a signed-in user (sync).
    var userId: String?
    /// Number of times this habit was completed on this day (for repeating/interval habits).
    /// 0 means not started; for non-repeating habits this stays 0 and isCompleted is used instead.
    var completionCount: Int = 0
    
    init(date: Date, isCompleted: Bool = true, isSkipped: Bool = false, skipReason: String? = nil, userId: String? = nil) {
        self.id = UUID()
        self.date = date.startOfDay
        self.isCompleted = isCompleted
        self.isSkipped = isSkipped
        self.skipReason = skipReason
        self.updatedAt = .now
        self.userId = userId
    }
}

@available(iOS 17.0, macOS 14.0, *)
extension HabitEntry {
    /// Ordering used to pick the "best" of several same-day entries.
    static func isLessComplete(_ a: HabitEntry, than b: HabitEntry, countsAsCompleted: (HabitEntry) -> Bool) -> Bool {
        let ac = countsAsCompleted(a), bc = countsAsCompleted(b)
        if ac != bc { return !ac }
        if a.completionCount != b.completionCount { return a.completionCount < b.completionCount }
        if a.isSkipped != b.isSkipped { return !a.isSkipped }
        return a.updatedAt < b.updatedAt
    }
}

// MARK: - Streak

@available(iOS 17.0, macOS 14.0, *)
@Model
final class Streak {
    @Attribute(.preserveValueOnDeletion) var id: UUID = UUID()
    var currentStreak: Int = 0
    var longestStreak: Int = 0
    var lastCompletedDate: Date?
    var streakStartDate: Date?
    var updatedAt: Date = Date()
    var habit: Habit?
    /// When non-nil, streak belongs to a signed-in user (sync).
    var userId: String?
    
    init(currentStreak: Int = 0, longestStreak: Int = 0, userId: String? = nil) {
        self.id = UUID()
        self.currentStreak = currentStreak
        self.longestStreak = longestStreak
        self.updatedAt = .now
        self.userId = userId
    }
}
