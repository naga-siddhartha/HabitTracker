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
            self.rescheduleAllReminders()
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
        if let entry = canonicalEntry(for: habit, on: date) {
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

    /// Mark all expected completions as done at once.
    func markAllComplete(for habit: Habit, on date: Date) {
        let expected = habit.expectedCompletions(on: date)
        if let entry = canonicalEntry(for: habit, on: date) {
            if entry.isSkipped { entry.isSkipped = false; entry.skipReason = nil }
            entry.completionCount = expected
            entry.isCompleted = true
            entry.updatedAt = .now
        } else {
            let newEntry = HabitEntry(date: date, isCompleted: true)
            newEntry.completionCount = expected
            habit.entries = (habit.entries ?? []) + [newEntry]
        }
        habit.updatedAt = .now
        updateStreak(for: habit)
        save()
        reloadWidgets()
    }

    /// Reset all completions for a repeating habit back to zero.
    func resetCompletion(for habit: Habit, on date: Date) {
        guard let entry = canonicalEntry(for: habit, on: date) else { return }
        entry.completionCount = 0
        entry.isCompleted = false
        entry.isSkipped = false
        entry.skipReason = nil
        entry.updatedAt = .now
        habit.updatedAt = .now
        updateStreak(for: habit)
        save()
        reloadWidgets()
    }

    /// Increment the completion count for a repeating habit by 1, capped at expectedCompletions.
    /// Tapping when already at max resets to 0.
    func incrementCompletion(for habit: Habit, on date: Date) {
        let expected = habit.expectedCompletions(on: date)
        if let entry = canonicalEntry(for: habit, on: date) {
            if entry.isSkipped {
                entry.isSkipped = false
                entry.skipReason = nil
            }
            let current = entry.completionCount > 0 ? entry.completionCount : (entry.isCompleted ? expected : 0)
            if current >= expected {
                entry.completionCount = 0
                entry.isCompleted = false
            } else {
                entry.completionCount = current + 1
                entry.isCompleted = entry.completionCount > 0
            }
            entry.updatedAt = .now
        } else {
            let newEntry = HabitEntry(date: date, isCompleted: true)
            newEntry.completionCount = 1
            habit.entries = (habit.entries ?? []) + [newEntry]
        }
        habit.updatedAt = .now
        updateStreak(for: habit)
        save()
        reloadWidgets()
    }
    
    func skipDay(for habit: Habit, on date: Date, reason: String? = nil) {
        if let entry = canonicalEntry(for: habit, on: date) {
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
        if let entry = canonicalEntry(for: habit, on: date) {
            entry.isSkipped = false
            entry.skipReason = nil
            entry.updatedAt = .now
        }
        
        habit.updatedAt = .now
        updateStreak(for: habit)
        save()
        reloadWidgets()
    }
    
    /// The single entry for a day, used before any write. If sync produced duplicate entries for
    /// the same day, they are folded into the most complete one and the extras are deleted, so
    /// every write leaves at most one entry per day.
    private func canonicalEntry(for habit: Habit, on date: Date) -> HabitEntry? {
        let sameDay = habit.entries(on: date)
        guard let keep = sameDay.max(by: { HabitEntry.isLessComplete($0, than: $1, countsAsCompleted: habit.countsAsCompleted) }) else {
            return nil
        }
        guard sameDay.count > 1 else { return keep }
        let duplicates = sameDay.filter { $0 !== keep }
        for dup in duplicates {
            keep.completionCount = max(keep.completionCount, dup.completionCount)
            if keep.isSkipped, keep.skipReason == nil { keep.skipReason = dup.skipReason }
            modelContext.delete(dup)
        }
        habit.entries = habit.entriesOrEmpty.filter { entry in !duplicates.contains { $0 === entry } }
        keep.updatedAt = .now
        return keep
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
    
    // MARK: - Reminders

    /// Rebuild all pending reminders from the current habits. Call after any change to habits or
    /// their reminder settings, and on launch so lost or stale reminders heal themselves.
    func rescheduleAllReminders() {
        let habits = fetchHabits()
            .filter { !$0.isArchived }
            .map {
                NotificationHabit(
                    id: $0.id, name: $0.name, frequency: $0.frequency,
                    reminderTimes: $0.reminderTimes, reminderNames: $0.reminderNames,
                    reminderSounds: $0.sounds,
                    reminderIntervalMinutes: $0.reminderIntervalMinutes,
                    reminderEndTime: $0.reminderEndTime,
                    activeDays: $0.activeDays
                )
            }
        NotificationService.shared.rescheduleAll(habits)
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
