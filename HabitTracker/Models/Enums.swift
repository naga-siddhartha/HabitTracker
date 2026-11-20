import Foundation
import SwiftUI

// MARK: - Reminder Sound

/// Sound played by a reminder notification.
nonisolated enum ReminderSound: String, Codable, CaseIterable, Sendable {
    case `default` = "Default"
    case chime = "Chime"
    case bell = "Bell"
    case alert = "Alert"
    case none = "None"
}

// MARK: - Habit Color

/// Preset habit color; `.custom` uses `Habit.customColorHex`.
nonisolated enum HabitColor: String, Codable, CaseIterable, Sendable {
    // `purple` stays decodable so existing habits keep their color, but isn't offered: it clashes
    // with the violet brand color.
    case red, orange, yellow, green, blue, purple, pink, indigo, teal, brown, custom

    /// The preset colors offered in the picker, in display order.
    static let pickerColors: [HabitColor] = [.red, .orange, .yellow, .green, .teal, .blue, .indigo, .pink, .brown]

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
        case .brown: .brown
        case .custom: .blue
        }
    }
}

// MARK: - Habit Frequency

/// How often a habit repeats. Weekly habits run on `Habit.activeDays`.
nonisolated enum HabitFrequency: String, Codable, Sendable {
    case daily, weekly
}

// MARK: - Weekday

/// Day of the week; raw values match `Calendar` weekday numbers (Sunday = 1).
nonisolated enum Weekday: Int, Codable, CaseIterable, Hashable, Sendable {
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
