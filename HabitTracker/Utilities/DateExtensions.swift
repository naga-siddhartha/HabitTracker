import Foundation
import SwiftUI

// MARK: - Color Extensions

extension Color {
    static var systemBackground: Color { Color(uiColor: .systemBackground) }
    static var systemGray6: Color { Color(uiColor: .systemGray6) }
    static var systemGray5: Color { Color(uiColor: .systemGray5) }
    static var systemGray4: Color { Color(uiColor: .systemGray4) }
}

// MARK: - Date Extensions

extension Date {
    /// Returns the start of the day
    var startOfDay: Date {
        return Calendar.current.startOfDay(for: self)
    }
    
    /// Returns the end of the day
    var endOfDay: Date {
        var components = DateComponents()
        components.day = 1
        components.second = -1
        return Calendar.current.date(byAdding: components, to: startOfDay) ?? self
    }
    
    /// Returns the start of the week
    var startOfWeek: Date? {
        let calendar = Calendar.current
        return calendar.dateInterval(of: .weekOfYear, for: self)?.start
    }
    
    /// Returns the end of the week
    var endOfWeek: Date? {
        guard let startOfWeek = startOfWeek else { return nil }
        var components = DateComponents()
        components.day = 7
        components.second = -1
        return Calendar.current.date(byAdding: components, to: startOfWeek)
    }
    
    /// Returns the start of the month
    var startOfMonth: Date? {
        let calendar = Calendar.current
        return calendar.dateInterval(of: .month, for: self)?.start
    }
    
    /// Returns the end of the month
    var endOfMonth: Date? {
        guard let startOfMonth = startOfMonth else { return nil }
        var components = DateComponents()
        components.month = 1
        components.second = -1
        return Calendar.current.date(byAdding: components, to: startOfMonth)
    }
    
    /// Returns the start of the year
    var startOfYear: Date? {
        let calendar = Calendar.current
        return calendar.dateInterval(of: .year, for: self)?.start
    }
    
    /// Returns the end of the year
    var endOfYear: Date? {
        guard let startOfYear = startOfYear else { return nil }
        var components = DateComponents()
        components.year = 1
        components.second = -1
        return Calendar.current.date(byAdding: components, to: startOfYear)
    }
    
    /// Returns the weekday
    var weekday: Weekday? {
        let calendar = Calendar.current
        let day = calendar.component(.weekday, from: self)
        return Weekday(rawValue: day)
    }
    
    /// Returns true if the date is today
    var isToday: Bool {
        return Calendar.current.isDateInToday(self)
    }
    
    /// Returns true if the date is in the current week
    var isInCurrentWeek: Bool {
        return Calendar.current.isDate(self, equalTo: Date(), toGranularity: .weekOfYear)
    }
    
    /// Returns true if the date is in the current month
    var isInCurrentMonth: Bool {
        return Calendar.current.isDate(self, equalTo: Date(), toGranularity: .month)
    }
    
    /// Returns true if the date is in the current year
    var isInCurrentYear: Bool {
        return Calendar.current.isDate(self, equalTo: Date(), toGranularity: .year)
    }
    
    /// Returns a date with only the time components (hour, minute, second)
    var timeOnly: Date {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour, .minute, .second], from: self)
        return calendar.date(from: components) ?? self
    }
    
    /// Returns a date string in short format
    var shortDateString: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        return formatter.string(from: self)
    }
    
    /// Returns a date string in medium format
    var mediumDateString: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: self)
    }
    
    /// Returns a time string
    var timeString: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: self)
    }
}
