import Foundation
import Combine

/// Service for calculating and managing streaks
class StreakService: ObservableObject {
    static let shared = StreakService()
    
    @Published var streaks: [Streak] = []
    
    private let habitService = HabitService.shared
    private let streaksKey = Constants.streaksKey
    
    private init() {
        loadStreaks()
    }
    
    /// Calculate and update streak for a habit
    func updateStreak(for habitId: UUID) {
        let calendar = Calendar.current
        let today = Date().startOfDay
        
        // Get all completed entries for this habit, sorted by date descending
        let entries = habitService.getEntries(for: habitId)
            .filter { $0.isCompleted }
            .sorted { $0.date > $1.date }
        
        guard !entries.isEmpty else {
            // No entries, reset streak
            if let index = streaks.firstIndex(where: { $0.habitId == habitId }) {
                var streak = streaks[index]
                streak.currentStreak = 0
                streak.lastCompletedDate = nil
                streak.streakStartDate = nil
                streak.updatedAt = Date()
                streaks[index] = streak
            } else {
                let streak = Streak(habitId: habitId, currentStreak: 0)
                streaks.append(streak)
            }
            saveStreaks()
            return
        }
        
        let mostRecentEntry = entries[0]
        let mostRecentDate = mostRecentEntry.date
        
        // Check if most recent entry is today or yesterday (allows for same-day streak continuation)
        let daysSinceLastCompletion = calendar.dateComponents([.day], from: mostRecentDate, to: today).day ?? 0
        
        var currentStreak: Int = 0
        var streakStartDate: Date? = nil
        
        if daysSinceLastCompletion <= 1 {
            // Streak is still active
            currentStreak = 1
            streakStartDate = mostRecentDate
            
            // Count backwards to find the streak length
            var checkDate = mostRecentDate
            while true {
                // Check if there's an entry for this date
                if entries.contains(where: { $0.date == checkDate }) {
                    currentStreak += 1
                    streakStartDate = checkDate
                    
                    // Move to previous day
                    guard let previousDay = calendar.date(byAdding: .day, value: -1, to: checkDate) else {
                        break
                    }
                    checkDate = previousDay
                } else {
                    break
                }
            }
            
            // Adjust for today if not completed yet
            if daysSinceLastCompletion == 1 && !habitService.isHabitCompleted(habitId: habitId, date: today) {
                currentStreak -= 1
            }
        } else {
            // Streak is broken
            currentStreak = 0
        }
        
        // Update or create streak
        if let index = streaks.firstIndex(where: { $0.habitId == habitId }) {
            var streak = streaks[index]
            let previousLongest = streak.longestStreak
            streak.currentStreak = currentStreak
            streak.longestStreak = max(previousLongest, currentStreak)
            streak.lastCompletedDate = mostRecentDate
            streak.streakStartDate = streakStartDate
            streak.updatedAt = Date()
            streaks[index] = streak
        } else {
            let streak = Streak(
                habitId: habitId,
                currentStreak: currentStreak,
                longestStreak: currentStreak,
                lastCompletedDate: mostRecentDate,
                streakStartDate: streakStartDate
            )
            streaks.append(streak)
        }
        
        saveStreaks()
    }
    
    /// Get streak for a habit
    func getStreak(for habitId: UUID) -> Streak? {
        return streaks.first { $0.habitId == habitId }
    }
    
    /// Update all streaks (call after entries are modified)
    func updateAllStreaks() {
        let habitIds = habitService.getActiveHabits().map { $0.id }
        for habitId in habitIds {
            updateStreak(for: habitId)
        }
    }
    
    // MARK: - Persistence
    
    private func saveStreaks() {
        if let encoded = try? JSONEncoder().encode(streaks) {
            UserDefaults.standard.set(encoded, forKey: streaksKey)
        }
    }
    
    private func loadStreaks() {
        if let data = UserDefaults.standard.data(forKey: streaksKey),
           let decoded = try? JSONDecoder().decode([Streak].self, from: data) {
            streaks = decoded
        }
    }
}
