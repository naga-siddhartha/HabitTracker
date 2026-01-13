import Foundation

/// Represents a single completion entry for a habit on a specific date
struct HabitEntry: Identifiable, Codable, Hashable {
    let id: UUID
    let habitId: UUID
    let date: Date // Date of completion (time component should be midnight)
    var isCompleted: Bool
    var notes: String?
    var createdAt: Date
    var updatedAt: Date
    
    init(
        id: UUID = UUID(),
        habitId: UUID,
        date: Date,
        isCompleted: Bool = true,
        notes: String? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.habitId = habitId
        // Normalize date to midnight
        let calendar = Calendar.current
        self.date = calendar.startOfDay(for: date)
        self.isCompleted = isCompleted
        self.notes = notes
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
