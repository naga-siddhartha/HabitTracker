import Foundation

/// Represents a streak for a habit
struct Streak: Identifiable, Codable {
    let id: UUID
    let habitId: UUID
    var currentStreak: Int // Current consecutive days
    var longestStreak: Int // Longest streak ever achieved
    var lastCompletedDate: Date? // Last date the habit was completed
    var streakStartDate: Date? // Start date of current streak
    var updatedAt: Date
    
    init(
        id: UUID = UUID(),
        habitId: UUID,
        currentStreak: Int = 0,
        longestStreak: Int = 0,
        lastCompletedDate: Date? = nil,
        streakStartDate: Date? = nil,
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.habitId = habitId
        self.currentStreak = currentStreak
        self.longestStreak = longestStreak
        self.lastCompletedDate = lastCompletedDate
        self.streakStartDate = streakStartDate
        self.updatedAt = updatedAt
    }
}
