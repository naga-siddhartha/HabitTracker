import Foundation

// MARK: - Streak Calculator

@available(iOS 17.0, macOS 14.0, *)
struct StreakCalculator {
    private let calendar = Calendar.current
    
    func calculate(for habit: Habit) -> (current: Int, longest: Int, lastCompleted: Date?, streakStart: Date?) {
        let today = Date.now.startOfDay
        
        let completedEntries = habit.entriesOrEmpty
            .filter { $0.isCompleted && $0.date <= today }
            .sorted { $0.date > $1.date }
        
        guard let mostRecent = completedEntries.first else {
            return (0, habit.streak?.longestStreak ?? 0, nil, nil)
        }
        
        let daysSince = calendar.dateComponents([.day], from: mostRecent.date, to: today).day ?? 0
        
        // Check if streak is broken
        if daysSince > 1 && isStreakBroken(habit: habit, from: mostRecent.date, to: today) {
            return (0, habit.streak?.longestStreak ?? 0, mostRecent.date, nil)
        }
        
        // Count streak backwards
        var currentStreak = 1
        var streakStart = mostRecent.date
        var checkDate = mostRecent.date
        
        while let prevDay = calendar.date(byAdding: .day, value: -1, to: checkDate) {
            if habit.isCompleted(on: prevDay) {
                currentStreak += 1
                streakStart = prevDay
                checkDate = prevDay
            } else if habit.isSkipped(on: prevDay) {
                checkDate = prevDay
            } else {
                break
            }
        }
        
        // Adjust if today is not completed/skipped
        if daysSince == 1 && !habit.isCompleted(on: today) && !habit.isSkipped(on: today) {
            currentStreak = max(0, currentStreak - 1)
        }
        
        let longest = max(habit.streak?.longestStreak ?? 0, currentStreak)
        return (currentStreak, longest, mostRecent.date, streakStart)
    }
    
    private func isStreakBroken(habit: Habit, from startDate: Date, to endDate: Date) -> Bool {
        var checkDate = startDate
        while let nextDay = calendar.date(byAdding: .day, value: 1, to: checkDate), nextDay < endDate {
            if !habit.isSkipped(on: nextDay) && !habit.isCompleted(on: nextDay) {
                return true
            }
            checkDate = nextDay
        }
        return false
    }
}
