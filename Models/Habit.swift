import Foundation
import SwiftUI

/// Represents a habit that can be tracked
struct Habit: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    var description: String?
    var iconName: String? // Name of generated/selected icon
    var iconImageData: Data? // Store generated icon image data
    var color: HabitColor
    var frequency: HabitFrequency
    var reminderTimes: [Date] // Times of day for reminders (stored as time components)
    var activeDays: Set<Weekday>? // Days of week when habit is active (nil = all days)
    var customPattern: String? // Custom pattern like "ULRULRR"
    var patternMapping: [String: String]? // Maps pattern characters to descriptions
    var createdAt: Date
    var updatedAt: Date
    var isArchived: Bool
    
    init(
        id: UUID = UUID(),
        name: String,
        description: String? = nil,
        iconName: String? = nil,
        iconImageData: Data? = nil,
        color: HabitColor = .blue,
        frequency: HabitFrequency = .daily,
        reminderTimes: [Date] = [],
        activeDays: Set<Weekday>? = nil,
        customPattern: String? = nil,
        patternMapping: [String: String]? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        isArchived: Bool = false
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.iconName = iconName
        self.iconImageData = iconImageData
        self.color = color
        self.frequency = frequency
        self.reminderTimes = reminderTimes
        self.activeDays = activeDays
        self.customPattern = customPattern
        self.patternMapping = patternMapping
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.isArchived = isArchived
    }
}

/// Habit color options
enum HabitColor: String, Codable, CaseIterable {
    case red, orange, yellow, green, blue, purple, pink, indigo, teal
    
    var color: Color {
        switch self {
        case .red: return .red
        case .orange: return .orange
        case .yellow: return .yellow
        case .green: return .green
        case .blue: return .blue
        case .purple: return .purple
        case .pink: return .pink
        case .indigo: return .indigo
        case .teal: return .teal
        }
    }
}

/// Habit frequency options
enum HabitFrequency: String, Codable {
    case daily
    case weekly
    case custom // Uses custom pattern
}

/// Weekday enumeration
enum Weekday: Int, Codable, CaseIterable, Hashable {
    case sunday = 1
    case monday = 2
    case tuesday = 3
    case wednesday = 4
    case thursday = 5
    case friday = 6
    case saturday = 7
    
    var shortName: String {
        switch self {
        case .sunday: return "Sun"
        case .monday: return "Mon"
        case .tuesday: return "Tue"
        case .wednesday: return "Wed"
        case .thursday: return "Thu"
        case .friday: return "Fri"
        case .saturday: return "Sat"
        }
    }
    
    var fullName: String {
        switch self {
        case .sunday: return "Sunday"
        case .monday: return "Monday"
        case .tuesday: return "Tuesday"
        case .wednesday: return "Wednesday"
        case .thursday: return "Thursday"
        case .friday: return "Friday"
        case .saturday: return "Saturday"
        }
    }
}
