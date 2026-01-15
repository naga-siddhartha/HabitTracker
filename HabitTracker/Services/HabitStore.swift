import Foundation
import SwiftData
import WidgetKit

// MARK: - Habit Store (Facade)

@available(iOS 17.0, macOS 14.0, *)
@MainActor
final class HabitStore {
    static let shared = HabitStore()
    
    let modelContainer: ModelContainer
    let modelContext: ModelContext
    
    private lazy var repository = HabitRepository(modelContext: modelContext)
    private let streakCalculator = StreakCalculator()
    
    private init() {
        do {
            modelContainer = try AppConfig.createModelContainer()
        } catch {
            modelContainer = try! ModelContainer(for: AppConfig.schema, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        }
        modelContext = modelContainer.mainContext
        modelContext.autosaveEnabled = true
    }
    
    // MARK: - Habits
    
    func fetchHabits(includeArchived: Bool = false) -> [Habit] {
        repository.fetchAll(includeArchived: includeArchived)
    }
    
    func addHabit(_ habit: Habit) {
        repository.add(habit)
        reloadWidgets()
    }
    
    func deleteHabit(_ habit: Habit) {
        repository.delete(habit)
        reloadWidgets()
    }
    
    // MARK: - Entries
    
    func toggleCompletion(for habit: Habit, on date: Date) {
        if let entry = habit.entry(for: date) {
            if entry.isSkipped {
                entry.isSkipped = false
                entry.skipReason = nil
                entry.isCompleted = true
            } else {
                entry.isCompleted.toggle()
            }
            entry.updatedAt = .now
        } else {
            habit.entries.append(HabitEntry(date: date))
        }
        
        habit.updatedAt = .now
        updateStreak(for: habit)
        save()
        reloadWidgets()
    }
    
    func skipDay(for habit: Habit, on date: Date, reason: String? = nil) {
        if let entry = habit.entry(for: date) {
            entry.isCompleted = false
            entry.isSkipped = true
            entry.skipReason = reason
            entry.updatedAt = .now
        } else {
            habit.entries.append(HabitEntry(date: date, isCompleted: false, isSkipped: true, skipReason: reason))
        }
        
        habit.updatedAt = .now
        updateStreak(for: habit)
        save()
        reloadWidgets()
    }
    
    func unskipDay(for habit: Habit, on date: Date) {
        if let entry = habit.entry(for: date) {
            entry.isSkipped = false
            entry.skipReason = nil
            entry.updatedAt = .now
        }
        
        habit.updatedAt = .now
        updateStreak(for: habit)
        save()
        reloadWidgets()
    }
    
    // MARK: - Streaks
    
    func updateStreak(for habit: Habit) {
        let result = streakCalculator.calculate(for: habit)
        
        if habit.streak == nil { habit.streak = Streak() }
        
        habit.streak?.currentStreak = result.current
        habit.streak?.longestStreak = result.longest
        habit.streak?.lastCompletedDate = result.lastCompleted
        habit.streak?.streakStartDate = result.streakStart
        habit.streak?.updatedAt = .now
    }
    
    func updateAllStreaks() {
        fetchHabits().forEach { updateStreak(for: $0) }
        save()
    }
    
    // MARK: - Persistence
    
    func save() {
        repository.save()
    }
    
    private func reloadWidgets() {
        WidgetCenter.shared.reloadAllTimelines()
    }
}
