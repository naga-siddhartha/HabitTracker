import AppIntents
import SwiftData
import WidgetKit

// MARK: - Toggle Habit Intent

struct ToggleHabitIntent: AppIntent {
    static var title: LocalizedStringResource = "Toggle Habit"
    static var description = IntentDescription("Mark a habit as complete or incomplete")
    
    @Parameter(title: "Habit ID")
    var habitId: String
    
    init() {}
    
    init(habitId: UUID) {
        self.habitId = habitId.uuidString
    }
    
    @MainActor
    func perform() async throws -> some IntentResult {
        guard let uuid = UUID(uuidString: habitId) else {
            return .result()
        }
        
        // Use the app's own store (CloudKit-backed when signed in) rather than opening a second
        // container on the same file, and go through HabitStore so day matching, interval habits,
        // streaks and widget data all stay consistent with in-app taps.
        let store = HabitStore.shared
        guard let habit = store.fetchHabits().first(where: { $0.id == uuid }) else {
            return .result()
        }

        let today = Date.now
        if habit.reminderIntervalMinutes > 0 {
            if habit.isDone(on: today) {
                store.resetCompletion(for: habit, on: today)
            } else {
                store.markAllComplete(for: habit, on: today)
            }
        } else {
            store.toggleCompletion(for: habit, on: today)
        }

        return .result()
    }
}

// MARK: - App Shortcuts

struct HabitTrackerShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: ToggleHabitIntent(),
            phrases: [
                "Complete a habit in \(.applicationName)",
                "Mark habit done in \(.applicationName)"
            ],
            shortTitle: "Complete Habit",
            systemImageName: "checkmark.circle"
        )
    }
}
