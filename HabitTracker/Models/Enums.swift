import Foundation
import SwiftUI

// MARK: - Reminder Sound

enum ReminderSound: String, Codable, CaseIterable, Sendable {
    case `default` = "Default"
    case chime = "Chime"
    case bell = "Bell"
    case alert = "Alert"
    case none = "None"
}

// MARK: - Habit Color

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

// MARK: - Habit Frequency

enum HabitFrequency: String, Codable, Sendable {
    case daily, weekly
}

// MARK: - Weekday

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
