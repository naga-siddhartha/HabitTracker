import Foundation
import Combine

/// Service for managing habits and habit entries
class HabitService: ObservableObject {
    static let shared = HabitService()
    
    @Published var habits: [Habit] = []
    @Published var entries: [HabitEntry] = []
    
    private let habitsKey = Constants.habitsKey
    private let entriesKey = Constants.entriesKey
    
    private init() {
        loadHabits()
        loadEntries()
    }
    
    // MARK: - Habit Management
    
    /// Add a new habit
    func addHabit(_ habit: Habit) {
        habits.append(habit)
        saveHabits()
    }
    
    /// Update an existing habit
    func updateHabit(_ habit: Habit) {
        guard let index = habits.firstIndex(where: { $0.id == habit.id }) else { return }
        var updatedHabit = habit
        updatedHabit.updatedAt = Date()
        habits[index] = updatedHabit
        saveHabits()
    }
    
    /// Delete a habit
    func deleteHabit(_ habit: Habit) {
        habits.removeAll { $0.id == habit.id }
        // Also delete all entries for this habit
        entries.removeAll { $0.habitId == habit.id }
        saveHabits()
        saveEntries()
    }
    
    /// Get a habit by ID
    func getHabit(id: UUID) -> Habit? {
        return habits.first { $0.id == id }
    }
    
    /// Get all active (non-archived) habits
    func getActiveHabits() -> [Habit] {
        return habits.filter { !$0.isArchived }
    }
    
    /// Archive a habit
    func archiveHabit(_ habit: Habit) {
        guard let index = habits.firstIndex(where: { $0.id == habit.id }) else { return }
        var updatedHabit = habit
        updatedHabit.isArchived = true
        updatedHabit.updatedAt = Date()
        habits[index] = updatedHabit
        saveHabits()
    }
    
    // MARK: - Entry Management
    
    /// Mark a habit as completed for a specific date
    func markHabitCompleted(habitId: UUID, date: Date, notes: String? = nil) {
        let normalizedDate = date.startOfDay
        
        // Check if entry already exists
        if let index = entries.firstIndex(where: { $0.habitId == habitId && $0.date == normalizedDate }) {
            var entry = entries[index]
            entry.isCompleted = true
            entry.notes = notes
            entry.updatedAt = Date()
            entries[index] = entry
        } else {
            let entry = HabitEntry(
                habitId: habitId,
                date: normalizedDate,
                isCompleted: true,
                notes: notes
            )
            entries.append(entry)
        }
        
        saveEntries()
    }
    
    /// Mark a habit as incomplete for a specific date
    func markHabitIncomplete(habitId: UUID, date: Date) {
        let normalizedDate = date.startOfDay
        
        if let index = entries.firstIndex(where: { $0.habitId == habitId && $0.date == normalizedDate }) {
            var entry = entries[index]
            entry.isCompleted = false
            entry.updatedAt = Date()
            entries[index] = entry
            saveEntries()
        }
    }
    
    /// Toggle habit completion for a specific date
    func toggleHabitCompletion(habitId: UUID, date: Date) {
        let normalizedDate = date.startOfDay
        
        if let entry = entries.first(where: { $0.habitId == habitId && $0.date == normalizedDate }) {
            if entry.isCompleted {
                markHabitIncomplete(habitId: habitId, date: date)
            } else {
                markHabitCompleted(habitId: habitId, date: date)
            }
        } else {
            markHabitCompleted(habitId: habitId, date: date)
        }
    }
    
    /// Get completion status for a habit on a specific date
    func isHabitCompleted(habitId: UUID, date: Date) -> Bool {
        let normalizedDate = date.startOfDay
        return entries.first(where: { $0.habitId == habitId && $0.date == normalizedDate })?.isCompleted ?? false
    }
    
    /// Get all entries for a habit
    func getEntries(for habitId: UUID) -> [HabitEntry] {
        return entries.filter { $0.habitId == habitId }
    }
    
    /// Get entries for a habit within a date range
    func getEntries(for habitId: UUID, from startDate: Date, to endDate: Date) -> [HabitEntry] {
        let normalizedStart = startDate.startOfDay
        let normalizedEnd = endDate.endOfDay
        
        return entries.filter { entry in
            entry.habitId == habitId &&
            entry.date >= normalizedStart &&
            entry.date <= normalizedEnd &&
            entry.isCompleted
        }
    }
    
    /// Get entries for a specific date
    func getEntries(for date: Date) -> [HabitEntry] {
        let normalizedDate = date.startOfDay
        return entries.filter { $0.date == normalizedDate && $0.isCompleted }
    }
    
    /// Check if a habit should be active on a specific date
    func isHabitActive(habit: Habit, on date: Date) -> Bool {
        // Check if habit is archived
        if habit.isArchived {
            return false
        }
        
        // Check active days
        if let activeDays = habit.activeDays, !activeDays.isEmpty {
            guard let weekday = date.weekday else { return false }
            if !activeDays.contains(weekday) {
                return false
            }
        }
        
        // Check custom pattern if applicable
        if habit.frequency == .custom, let pattern = habit.customPattern {
            // For custom patterns, check if the pattern value exists for this date
            let habitPattern = HabitPattern(
                pattern: pattern,
                mapping: habit.patternMapping ?? [:]
            )
            return habitPattern.value(for: date) != nil
        }
        
        return true
    }
    
    // MARK: - Persistence
    
    private func saveHabits() {
        if let encoded = try? JSONEncoder().encode(habits) {
            UserDefaults.standard.set(encoded, forKey: habitsKey)
        }
    }
    
    private func loadHabits() {
        if let data = UserDefaults.standard.data(forKey: habitsKey),
           let decoded = try? JSONDecoder().decode([Habit].self, from: data) {
            habits = decoded
        }
    }
    
    private func saveEntries() {
        if let encoded = try? JSONEncoder().encode(entries) {
            UserDefaults.standard.set(encoded, forKey: entriesKey)
        }
    }
    
    private func loadEntries() {
        if let data = UserDefaults.standard.data(forKey: entriesKey),
           let decoded = try? JSONDecoder().decode([HabitEntry].self, from: data) {
            entries = decoded
        }
    }
}
