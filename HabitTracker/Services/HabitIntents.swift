import AppIntents
import SwiftData
import WidgetKit

// MARK: - Toggle Habit Intent

/// Siri and Shortcuts action that completes or un-completes a habit for today.
struct ToggleHabitIntent: AppIntent {
    static let title: LocalizedStringResource = "Toggle Habit"
    static let description = IntentDescription("Mark a habit as complete or incomplete")
    
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
        
        // Go through the app's store so this behaves exactly like an in-app tap, and never opens
        // a second container on the same file.
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

/// App Shortcuts exposed to Siri and Spotlight.
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
