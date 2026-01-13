import Foundation

struct Constants {
    // App Information
    static let appName = "HabitTracker"
    
    // Storage Keys
    static let habitsKey = "habits"
    static let entriesKey = "habitEntries"
    static let streaksKey = "streaks"
    static let achievementsKey = "achievements"
    
    // Default Values
    static let defaultReminderTime = DateComponents(hour: 9, minute: 0) // 9:00 AM
    
    // Achievement Thresholds
    struct Achievements {
        static let firstHabit = 1
        static let streak7Days = 7
        static let streak30Days = 30
        static let streak100Days = 100
        static let perfectWeek = 7
        static let perfectMonth = 30
    }
    
    // Icon Generation
    struct IconGeneration {
        static let defaultIconSize: CGFloat = 512
        static let cacheDirectory = "GeneratedIcons"
    }
}
