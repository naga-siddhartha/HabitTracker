import Foundation

struct WidgetHabit: Codable, Sendable {
    let id: String
    let name: String
    let emoji: String?
    let colorName: String
    let isCompleted: Bool
    let isSkipped: Bool
    let completionCount: Int
    let expectedCount: Int
}

/// Shared data store for the home screen widget. Uses App Groups so both the main app and widget extension can read/write.
/// `nonisolated` so the app target's default MainActor isolation doesn't apply: the widget and
/// background code read this too, and it only touches thread-safe UserDefaults.
nonisolated enum WidgetDataStore {
    static let appGroupIdentifier = "group.com.nagasiddharthadonepudi.HabitTracker"

    /// Cached so we only open the App Group suite once per process (avoids repeated CFPreferences warnings when container is unavailable, e.g. Simulator).
    /// UserDefaults is thread-safe (documented by Apple) but not marked Sendable in the SDK.
    nonisolated(unsafe) private static let userDefaults: UserDefaults? = UserDefaults(suiteName: appGroupIdentifier)

    private static let completedCountKey = "widget_completedCount"
    private static let totalCountKey = "widget_totalCount"
    private static let habitsKey = "widget_habits"
    private static let pendingTogglesKey = "widget_pendingToggles"

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

    static func writeHabits(_ habits: [WidgetHabit]) {
        guard let data = try? JSONEncoder().encode(habits) else { return }
        userDefaults?.set(data, forKey: habitsKey)
        userDefaults?.synchronize()
    }

    static func readHabits() -> [WidgetHabit] {
        guard let data = userDefaults?.data(forKey: habitsKey),
              let habits = try? JSONDecoder().decode([WidgetHabit].self, from: data) else { return [] }
        return habits
    }

    static func appendPendingToggle(habitID: String) {
        var pending = readPendingToggles()
        guard !pending.contains(habitID) else { return }
        pending.append(habitID)
        userDefaults?.set(pending, forKey: pendingTogglesKey)
        userDefaults?.synchronize()
    }

    static func readAndClearPendingToggles() -> [String] {
        let pending = (userDefaults?.stringArray(forKey: pendingTogglesKey)) ?? []
        userDefaults?.removeObject(forKey: pendingTogglesKey)
        userDefaults?.synchronize()
        return pending
    }

    private static func readPendingToggles() -> [String] {
        (userDefaults?.stringArray(forKey: pendingTogglesKey)) ?? []
    }
}
