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
        
        let container = try AppConfig.createModelContainer()
        let context = container.mainContext
        
        var descriptor = FetchDescriptor<Habit>()
        descriptor.predicate = #Predicate { $0.id == uuid }
        
        guard let habit = try? context.fetch(descriptor).first else {
            return .result()
        }
        
        let today = Date.now.startOfDay
        
        if let entry = habit.entries.first(where: { $0.date == today }) {
            entry.isCompleted.toggle()
            entry.updatedAt = Date.now
        } else {
            let entry = HabitEntry(date: today)
            habit.entries.append(entry)
        }
        
        habit.updatedAt = Date.now
        try? context.save()
        
        WidgetCenter.shared.reloadAllTimelines()
        
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
