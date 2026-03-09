import Foundation
import SwiftData

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
    var frequencyRaw: String = HabitFrequency.daily.rawValue
    var reminderTimes: [Date] = []
    var reminderNames: [String] = []
    var reminderSounds: [String] = []
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
        activeDays: Set<Weekday> = []
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
}

// MARK: - Status Checks

@available(iOS 17.0, macOS 14.0, *)
extension Habit {
    func isActive(on date: Date) -> Bool {
        if frequency == .weekly && !activeDays.isEmpty {
            guard let weekday = date.weekday else { return false }
            return activeDays.contains(weekday)
        }
        return true
    }
    
    func isCompleted(on date: Date) -> Bool {
        let cal = Calendar.current
        return entriesOrEmpty.contains { cal.isDate($0.date, inSameDayAs: date) && $0.isCompleted }
    }

    func isSkipped(on date: Date) -> Bool {
        let cal = Calendar.current
        return entriesOrEmpty.contains { cal.isDate($0.date, inSameDayAs: date) && $0.isSkipped }
    }

    func entry(for date: Date) -> HabitEntry? {
        let cal = Calendar.current
        return entriesOrEmpty.first { cal.isDate($0.date, inSameDayAs: date) }
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
