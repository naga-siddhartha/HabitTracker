import Foundation

// MARK: - Reminder (form model for add/edit habit)

struct HabitReminder: Identifiable {
    let id = UUID()
    var name: String
    var time: Date
    var sound: ReminderSound
}
