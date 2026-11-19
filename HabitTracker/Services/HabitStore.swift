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
    /// the same day, they are folded into the most complete one first.
    private func canonicalEntry(for habit: Habit, on date: Date) -> HabitEntry? {
        fold(habit.entries(on: date), in: habit)
    }

    /// Fold same-day entries into the most complete one and delete the rest. The choice is
    /// deterministic, so two devices merging the same duplicates end up with the same result.
    @discardableResult
    private func fold(_ sameDay: [HabitEntry], in habit: Habit) -> HabitEntry? {
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
        return keep
    }

    // MARK: - Duplicate cleanup

    /// Merge habits that share a name, and same-day entries inside each habit.
    ///
    /// Duplicates come from sync: the same habit set up on two devices before signing in, or a
    /// template added on each. The app has always treated a name as one habit (Home and Stats
    /// grouped by name), so this makes the data match. The surviving habit is the one with the
    /// lowest id, which every device agrees on, so merges on two devices never fight.
    @discardableResult
    func mergeDuplicates() -> Int {
        var removed = 0
        let byName = Dictionary(grouping: fetchHabits()) { $0.name.trimmingCharacters(in: .whitespacesAndNewlines) }
        for (name, group) in byName where !name.isEmpty && group.count > 1 {
            let sorted = group.sorted { $0.id.uuidString < $1.id.uuidString }
            let keeper = sorted[0]
            for dup in sorted.dropFirst() {
                keeper.createdAt = min(keeper.createdAt, dup.createdAt)
                // Detach entries before deleting, or the cascade rule would delete them too.
                let moved = dup.entriesOrEmpty
                dup.entries = []
                keeper.entries = keeper.entriesOrEmpty + moved
                modelContext.delete(dup)
                removed += 1
            }
            // Visible if any copy was visible.
            keeper.isArchived = group.allSatisfy(\.isArchived)
            keeper.updatedAt = .now
        }
        for habit in fetchHabits() {
            let byDay = Dictionary(grouping: habit.entriesOrEmpty) { Calendar.current.storedDayKey(for: $0.date) }
            for (_, sameDay) in byDay where sameDay.count > 1 {
                fold(sameDay, in: habit)
                removed += sameDay.count - 1
            }
        }
        if removed > 0 {
            save()
        }
        return removed
    }

    /// Called after CloudKit imports changes from another device.
    func handleRemoteChanges() {
        mergeDuplicates()
        updateAllStreaks()
        writeWidgetData()
        WidgetCenter.shared.reloadAllTimelines()
        rescheduleAllReminders()
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
