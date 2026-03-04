import Foundation
import SwiftUI

// MARK: - Cross-Platform Colors

extension Color {
    #if os(iOS) || os(visionOS)
    static var systemBackground: Color { Color(uiColor: .systemBackground) }
    static var systemGray6: Color { Color(uiColor: .systemGray6) }
    static var systemGray5: Color { Color(uiColor: .systemGray5) }
    static var systemGray4: Color { Color(uiColor: .systemGray4) }
    static var systemGroupedBackground: Color { Color(uiColor: .systemGroupedBackground) }
    static var secondarySystemGroupedBackground: Color { Color(uiColor: .secondarySystemGroupedBackground) }
    #elseif os(macOS)
    static var systemBackground: Color { Color(nsColor: .windowBackgroundColor) }
    static var systemGray6: Color { Color(nsColor: .controlBackgroundColor) }
    static var systemGray5: Color { Color(nsColor: .separatorColor) }
    static var systemGray4: Color { Color(nsColor: .tertiaryLabelColor) }
    static var systemGroupedBackground: Color { Color(nsColor: .windowBackgroundColor) }
    static var secondarySystemGroupedBackground: Color { Color(nsColor: .controlBackgroundColor) }
    #endif
}

// MARK: - Date Extensions

extension Date {
    var startOfDay: Date { Calendar.current.startOfDay(for: self) }
    
    var startOfWeek: Date? { Calendar.current.dateInterval(of: .weekOfYear, for: self)?.start }
    
    var endOfWeek: Date? {
        guard let start = startOfWeek else { return nil }
        return Calendar.current.date(byAdding: .day, value: 6, to: start)
    }
    
    var startOfMonth: Date? { Calendar.current.dateInterval(of: .month, for: self)?.start }
    
    var endOfMonth: Date? { Calendar.current.dateInterval(of: .month, for: self)?.end }
    
    var startOfYear: Date? { Calendar.current.dateInterval(of: .year, for: self)?.start }
    
    var endOfYear: Date? { Calendar.current.dateInterval(of: .year, for: self)?.end }
    
    var weekday: Weekday? { Weekday(rawValue: Calendar.current.component(.weekday, from: self)) }
    
    var isToday: Bool { Calendar.current.isDateInToday(self) }
    
    var mediumDateString: String {
        formatted(date: .abbreviated, time: .omitted)
    }
}
