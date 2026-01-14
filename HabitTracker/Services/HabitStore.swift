import Foundation
import SwiftData
import WidgetKit

@MainActor
final class HabitStore {
    let modelContainer: ModelContainer
    let modelContext: ModelContext
    
    static let shared = HabitStore()
    
    private init() {
        do {
            modelContainer = try AppConfig.createModelContainer()
            modelContext = modelContainer.mainContext
            modelContext.autosaveEnabled = true
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }
    
    // MARK: - Habits
    
    func fetchHabits(includeArchived: Bool = false) -> [Habit] {
        var descriptor = FetchDescriptor<Habit>(sortBy: [SortDescriptor(\.createdAt, order: .reverse)])
        if !includeArchived {
            descriptor.predicate = #Predicate { !$0.isArchived }
        }
        return (try? modelContext.fetch(descriptor)) ?? []
    }
    
    func addHabit(_ habit: Habit) {
        modelContext.insert(habit)
        habit.streak = Streak()
        save()
        reloadWidgets()
    }
    
    func deleteHabit(_ habit: Habit) {
        modelContext.delete(habit)
        save()
        reloadWidgets()
    }
    
    // MARK: - Entries
    
    func toggleCompletion(for habit: Habit, on date: Date) {
        let normalized = date.startOfDay
        
        if let entry = habit.entry(for: normalized) {
            if entry.isSkipped {
                // If skipped, mark as completed instead
                entry.isSkipped = false
                entry.skipReason = nil
                entry.isCompleted = true
            } else {
                entry.isCompleted.toggle()
            }
            entry.updatedAt = .now
        } else {
            let entry = HabitEntry(date: normalized)
            habit.entries.append(entry)
        }
        
        habit.updatedAt = .now
        updateStreak(for: habit)
        save()
        reloadWidgets()
    }
    
    func skipDay(for habit: Habit, on date: Date, reason: String? = nil) {
        let normalized = date.startOfDay
        
        if let entry = habit.entry(for: normalized) {
            entry.isCompleted = false
            entry.isSkipped = true
            entry.skipReason = reason
            entry.updatedAt = .now
        } else {
            let entry = HabitEntry(date: normalized, isCompleted: false, isSkipped: true, skipReason: reason)
            habit.entries.append(entry)
        }
        
        habit.updatedAt = .now
        updateStreak(for: habit)
        save()
        reloadWidgets()
    }
    
    func unskipDay(for habit: Habit, on date: Date) {
        let normalized = date.startOfDay
        
        if let entry = habit.entry(for: normalized) {
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
        let calendar = Calendar.current
        let today = Date.now.startOfDay
        
        // Get completed and skipped entries up to today
        let relevantEntries = habit.entries
            .filter { ($0.isCompleted || $0.isSkipped) && $0.date <= today }
            .sorted { $0.date > $1.date }
        
        let completedEntries = relevantEntries.filter { $0.isCompleted }
        
        guard let mostRecentCompleted = completedEntries.first else {
            habit.streak?.currentStreak = 0
            habit.streak?.lastCompletedDate = nil
            habit.streak?.streakStartDate = nil
            return
        }
        
        let daysSince = calendar.dateComponents([.day], from: mostRecentCompleted.date, to: today).day ?? 0
        
        // Check if streak is broken (more than 1 day gap without skip)
        var streakBroken = false
        if daysSince > 1 {
            // Check if all days between last completion and today are skipped
            var checkDate = mostRecentCompleted.date
            while let nextDay = calendar.date(byAdding: .day, value: 1, to: checkDate), nextDay < today {
                if !habit.isSkipped(on: nextDay) && !habit.isCompleted(on: nextDay) {
                    streakBroken = true
                    break
                }
                checkDate = nextDay
            }
        }
        
        guard !streakBroken else {
            habit.streak?.currentStreak = 0
            habit.streak?.lastCompletedDate = mostRecentCompleted.date
            return
        }
        
        // Count streak backwards, skipping over skipped days
        var currentStreak = 1
        var streakStart = mostRecentCompleted.date
        var checkDate = mostRecentCompleted.date
        
        while let prevDay = calendar.date(byAdding: .day, value: -1, to: checkDate) {
            if habit.isCompleted(on: prevDay) {
                currentStreak += 1
                streakStart = prevDay
                checkDate = prevDay
            } else if habit.isSkipped(on: prevDay) {
                // Skip over skipped days without breaking streak
                checkDate = prevDay
            } else {
                break
            }
        }
        
        // Adjust if today is not completed and not skipped
        if daysSince == 1 && !habit.isCompleted(on: today) && !habit.isSkipped(on: today) {
            currentStreak = max(0, currentStreak - 1)
        }
        
        if habit.streak == nil {
            habit.streak = Streak()
        }
        
        habit.streak?.currentStreak = currentStreak
        habit.streak?.longestStreak = max(habit.streak?.longestStreak ?? 0, currentStreak)
        habit.streak?.lastCompletedDate = mostRecentCompleted.date
        habit.streak?.streakStartDate = streakStart
        habit.streak?.updatedAt = .now
    }
    
    func updateAllStreaks() {
        fetchHabits().forEach { updateStreak(for: $0) }
        save()
    }
    
    // MARK: - Persistence
    
    func save() {
        guard modelContext.hasChanges else { return }
        try? modelContext.save()
    }
    
    // MARK: - Widgets
    
    private func reloadWidgets() {
        WidgetCenter.shared.reloadAllTimelines()
    }
}
