import Foundation

/// Represents an achievement/badge
struct Achievement: Identifiable, Codable {
    let id: UUID
    var name: String
    var description: String
    var iconName: String
    var criteria: AchievementCriteria
    var isUnlocked: Bool
    var unlockedDate: Date?
    var progress: Double // 0.0 to 1.0
    
    init(
        id: UUID = UUID(),
        name: String,
        description: String,
        iconName: String,
        criteria: AchievementCriteria,
        isUnlocked: Bool = false,
        unlockedDate: Date? = nil,
        progress: Double = 0.0
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.iconName = iconName
        self.criteria = criteria
        self.isUnlocked = isUnlocked
        self.unlockedDate = unlockedDate
        self.progress = progress
    }
}

/// Criteria for unlocking achievements
enum AchievementCriteria: Codable {
    case streak(days: Int) // Achieve X day streak
    case totalCompletions(count: Int) // Complete habit X times
    case perfectWeek // Complete all days in a week
    case perfectMonth // Complete all days in a month
    case habitCount(count: Int) // Create X habits
    case custom(description: String) // Custom criteria
}
