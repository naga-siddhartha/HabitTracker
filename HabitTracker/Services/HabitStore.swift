import Foundation
import SwiftData
import WidgetKit

// MARK: - Habit Store (Facade)

@available(iOS 17.0, macOS 14.0, *)
@MainActor
final class HabitStore {
    static let shared = HabitStore()

    private let provider = ModelContainerProvider.shared
    var modelContainer: ModelContainer { provider.currentContainer }
    var modelContext: ModelContext {
        let ctx = provider.currentContainer.mainContext
        ctx.autosaveEnabled = true
        return ctx
    }

    private var repository: HabitRepository { HabitRepository(modelContext: modelContext) }
    private let streakCalculator = StreakCalculator()

    private init() {}
    
    // MARK: - Habits
    
    func fetchHabits() -> [Habit] {
        repository.fetchAll()
    }
    
    func addHabit(_ habit: Habit) {
        repository.add(habit)
        reloadWidgets()
    }
    
    func deleteHabit(_ habit: Habit) {
        // Defer delete to next run loop so SwiftUI finishes current render cycle.
        // Prevents "model instance was invalidated" crash when views still reference entries.
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.repository.delete(habit)
            self.reloadWidgets()
        }
    }

    /// Synchronous delete for reset flow. Call from MainActor. Dismisses overlay when done.
    func deleteAllHabitsImmediate() {
        repository.deleteAll()
        writeWidgetData()
        // Defer widget reload so overlay dismisses quickly; widget updates shortly after.
        DispatchQueue.main.async { WidgetCenter.shared.reloadAllTimelines() }
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
            habit.entries = (habit.entries ?? []) + [HabitEntry(date: date)]
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
            habit.entries = (habit.entries ?? []) + [HabitEntry(date: date, isCompleted: false, isSkipped: true, skipReason: reason)]
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

    /// Push local changes and pull latest from iCloud (when signed in). Saves, then reconnects the CloudKit-backed container so remote changes from other devices are merged, then refreshes widgets.
    func syncNow() {
        save()
        if KeychainHelper.loadUserId() != nil {
            ModelContainerProvider.shared.recreateContainerWithCloudKit { [weak self] in
                self?.writeWidgetData()
                WidgetCenter.shared.reloadAllTimelines()
            }
        } else {
            reloadWidgets()
        }
    }
    
    private func reloadWidgets() {
        writeWidgetData()
        WidgetCenter.shared.reloadAllTimelines()
    }

    /// Write today's habit counts to shared UserDefaults for the widget. Call on launch and when data changes.
    func writeWidgetData() {
        let habits = fetchHabits().filter { !$0.isArchived }
        let today = Date.now
        let todayHabits = habits.filter { $0.isActive(on: today) }
        let completed = todayHabits.filter { $0.isCompleted(on: today) }.count
        WidgetDataStore.write(completedCount: completed, totalCount: todayHabits.count)
    }
}
