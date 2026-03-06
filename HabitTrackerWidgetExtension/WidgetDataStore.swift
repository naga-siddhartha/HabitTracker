import Foundation

/// Shared data store for the home screen widget. Uses App Groups so both the main app and widget extension can read/write.
enum WidgetDataStore {
    static let appGroupIdentifier = "group.com.nagasiddharthadonepudi.HabitTracker"

    private static var userDefaults: UserDefaults? {
        UserDefaults(suiteName: appGroupIdentifier)
    }

    private static let completedCountKey = "widget_completedCount"
    private static let totalCountKey = "widget_totalCount"

    /// Write today's habit counts for the widget to display.
    static func write(completedCount: Int, totalCount: Int) {
        userDefaults?.set(completedCount, forKey: completedCountKey)
        userDefaults?.set(totalCount, forKey: totalCountKey)
        userDefaults?.synchronize()
    }

    /// Read today's habit counts. Returns (0, 0) if no data.
    static func read() -> (completedCount: Int, totalCount: Int) {
        guard let defaults = userDefaults else { return (0, 0) }
        let completed = defaults.integer(forKey: completedCountKey)
        let total = defaults.integer(forKey: totalCountKey)
        return (completed, total)
    }
}
