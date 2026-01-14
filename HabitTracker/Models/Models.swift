import Foundation
import SwiftData
import SwiftUI

@Model
final class Habit {
    @Attribute(.preserveValueOnDeletion)
    var id: UUID
    
    var name: String
    var habitDescription: String?
    var iconName: String?
    var colorName: String
    var frequencyRaw: String
    var reminderTimes: [Date]
    var reminderNames: [String]
    var reminderSounds: [String]
    var activeDaysRaw: [Int]
    var createdAt: Date
    var updatedAt: Date
    var isArchived: Bool
    
    @Relationship(deleteRule: .cascade, inverse: \HabitEntry.habit)
    var entries: [HabitEntry] = []
    
    @Relationship(deleteRule: .cascade, inverse: \Streak.habit)
    var streak: Streak?
    
    init(
        name: String,
        description: String? = nil,
        iconName: String? = nil,
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
        self.colorName = color.rawValue
        self.frequencyRaw = frequency.rawValue
        self.reminderTimes = reminderTimes
        self.reminderNames = reminderNames
        self.reminderSounds = reminderSounds.map(\.rawValue)
        self.activeDaysRaw = activeDays.map(\.rawValue)
        self.createdAt = .now
        self.updatedAt = .now
        self.isArchived = false
    }
    
    // MARK: - Computed Properties
    
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
    
    // MARK: - Methods
    
    func isActive(on date: Date) -> Bool {
        guard !isArchived else { return false }
        
        if frequency == .weekly && !activeDays.isEmpty {
            guard let weekday = date.weekday else { return false }
            return activeDays.contains(weekday)
        }
        return true
    }
    
    func isCompleted(on date: Date) -> Bool {
        let normalized = date.startOfDay
        return entries.contains { $0.date == normalized && $0.isCompleted }
    }
    
    func isSkipped(on date: Date) -> Bool {
        let normalized = date.startOfDay
        return entries.contains { $0.date == normalized && $0.isSkipped }
    }
    
    func entry(for date: Date) -> HabitEntry? {
        let normalized = date.startOfDay
        return entries.first { $0.date == normalized }
    }
    
    // Cached completion check for batch operations
    func completionStatus(for dates: [Date]) -> [Date: Bool] {
        let normalizedDates = Set(dates.map { $0.startOfDay })
        var result: [Date: Bool] = [:]
        for entry in entries where normalizedDates.contains(entry.date) {
            result[entry.date] = entry.isCompleted
        }
        return result
    }
}

@Model
final class HabitEntry {
    @Attribute(.preserveValueOnDeletion)
    var id: UUID
    
    var date: Date
    var isCompleted: Bool
    var isSkipped: Bool
    var skipReason: String?
    var updatedAt: Date
    
    var habit: Habit?
    
    init(date: Date, isCompleted: Bool = true, isSkipped: Bool = false, skipReason: String? = nil) {
        self.id = UUID()
        self.date = Calendar.current.startOfDay(for: date)
        self.isCompleted = isCompleted
        self.isSkipped = isSkipped
        self.skipReason = skipReason
        self.updatedAt = .now
    }
}

@Model
final class Streak {
    @Attribute(.preserveValueOnDeletion)
    var id: UUID
    
    var currentStreak: Int
    var longestStreak: Int
    var lastCompletedDate: Date?
    var streakStartDate: Date?
    var updatedAt: Date
    
    var habit: Habit?
    
    init(currentStreak: Int = 0, longestStreak: Int = 0) {
        self.id = UUID()
        self.currentStreak = currentStreak
        self.longestStreak = longestStreak
        self.updatedAt = .now
    }
}

// MARK: - Enums (unchanged, but need to be outside @Model)

enum ReminderSound: String, Codable, CaseIterable, Sendable {
    case `default` = "Default"
    case chime = "Chime"
    case bell = "Bell"
    case alert = "Alert"
    case none = "None"
}

enum HabitColor: String, Codable, CaseIterable, Sendable {
    case red, orange, yellow, green, blue, purple, pink, indigo, teal
    
    var color: Color {
        switch self {
        case .red: .red
        case .orange: .orange
        case .yellow: .yellow
        case .green: .green
        case .blue: .blue
        case .purple: .purple
        case .pink: .pink
        case .indigo: .indigo
        case .teal: .teal
        }
    }
}

enum HabitFrequency: String, Codable, Sendable {
    case daily, weekly
}

enum Weekday: Int, Codable, CaseIterable, Hashable, Sendable {
    case sunday = 1, monday, tuesday, wednesday, thursday, friday, saturday
    
    var shortName: String {
        switch self {
        case .sunday: "Sun"
        case .monday: "Mon"
        case .tuesday: "Tue"
        case .wednesday: "Wed"
        case .thursday: "Thu"
        case .friday: "Fri"
        case .saturday: "Sat"
        }
    }
    
    var fullName: String {
        switch self {
        case .sunday: "Sunday"
        case .monday: "Monday"
        case .tuesday: "Tuesday"
        case .wednesday: "Wednesday"
        case .thursday: "Thursday"
        case .friday: "Friday"
        case .saturday: "Saturday"
        }
    }
}
