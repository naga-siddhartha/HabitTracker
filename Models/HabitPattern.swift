import Foundation

/// Represents a custom habit pattern and its interpretation
struct HabitPattern: Codable, Hashable {
    let pattern: String // e.g., "ULRULRR"
    let mapping: [String: String] // Maps characters to descriptions
    let startDate: Date? // Optional start date for pattern
    
    init(pattern: String, mapping: [String: String], startDate: Date? = nil) {
        self.pattern = pattern
        self.mapping = mapping
        self.startDate = startDate
    }
    
    /// Get the pattern value for a specific date
    /// Pattern repeats weekly starting from startDate or current week
    func value(for date: Date) -> String? {
        guard !pattern.isEmpty else { return nil }
        
        let calendar = Calendar.current
        let startDate = self.startDate ?? calendar.dateInterval(of: .weekOfYear, for: Date())?.start ?? Date()
        
        // Calculate days since start
        let daysSinceStart = calendar.dateComponents([.day], from: startDate, to: date).day ?? 0
        
        // Get day of week (0-6, where 0 is Sunday)
        let dayOfWeek = (calendar.component(.weekday, from: date) - 1) % 7
        
        // Calculate position in pattern (pattern repeats weekly)
        let patternIndex = dayOfWeek % pattern.count
        
        let index = pattern.index(pattern.startIndex, offsetBy: patternIndex)
        let character = String(pattern[index])
        
        return character
    }
    
    /// Get description for a pattern value
    func description(for value: String) -> String {
        return mapping[value] ?? value
    }
    
    /// Get all dates in a week with their pattern values
    func weekPattern(startingFrom date: Date = Date()) -> [(date: Date, value: String, description: String)] {
        let calendar = Calendar.current
        guard let weekStart = calendar.dateInterval(of: .weekOfYear, for: date)?.start else {
            return []
        }
        
        var result: [(date: Date, value: String, description: String)] = []
        
        for dayOffset in 0..<7 {
            guard let dayDate = calendar.date(byAdding: .day, value: dayOffset, to: weekStart) else {
                continue
            }
            
            if let value = self.value(for: dayDate) {
                let description = self.description(for: value)
                result.append((date: dayDate, value: value, description: description))
            }
        }
        
        return result
    }
}
