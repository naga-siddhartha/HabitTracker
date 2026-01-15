import Foundation
#if canImport(UserNotifications)
import UserNotifications
#endif

// Lightweight struct for notifications (doesn't need SwiftData)
struct NotificationHabit {
    let id: UUID
    let name: String
    let frequency: HabitFrequency
    let reminderTimes: [Date]
    let reminderNames: [String]
    let reminderSounds: [ReminderSound]
    let activeDays: Set<Weekday>
}

final class NotificationService {
    static let shared = NotificationService()
    
    private init() {
        #if canImport(UserNotifications)
        requestAuthorization()
        #endif
    }
    
    func requestAuthorization() {
        #if canImport(UserNotifications)
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in }
        #endif
    }
    
    func scheduleReminders(for habit: NotificationHabit) {
        #if canImport(UserNotifications)
        removeReminders(for: habit.id)
        guard !habit.reminderTimes.isEmpty else { return }
        
        let calendar = Calendar.current
        
        for (index, reminderTime) in habit.reminderTimes.enumerated() {
            let timeComponents = calendar.dateComponents([.hour, .minute], from: reminderTime)
            let reminderName = habit.reminderNames.indices.contains(index) ? habit.reminderNames[index] : "Reminder"
            let sound = habit.reminderSounds.indices.contains(index) ? habit.reminderSounds[index] : .default
            
            let content = UNMutableNotificationContent()
            content.title = reminderName
            content.body = "Time to work on: \(habit.name)"
            content.sound = notificationSound(for: sound)
            content.userInfo = ["habitId": habit.id.uuidString]
            
            var dateComponents = DateComponents()
            dateComponents.hour = timeComponents.hour
            dateComponents.minute = timeComponents.minute
            
            switch habit.frequency {
            case .daily:
                let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
                let request = UNNotificationRequest(
                    identifier: "\(habit.id.uuidString)-\(index)",
                    content: content,
                    trigger: trigger
                )
                UNUserNotificationCenter.current().add(request)
                
            case .weekly:
                let days = habit.activeDays.isEmpty ? Set(Weekday.allCases) : habit.activeDays
                for weekday in days {
                    dateComponents.weekday = weekday.rawValue
                    let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
                    let request = UNNotificationRequest(
                        identifier: "\(habit.id.uuidString)-\(index)-\(weekday.rawValue)",
                        content: content,
                        trigger: trigger
                    )
                    UNUserNotificationCenter.current().add(request)
                }
            }
        }
        #endif
    }
    
    func removeReminders(for habitId: UUID) {
        #if canImport(UserNotifications)
        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
            let ids = requests.filter { $0.identifier.hasPrefix(habitId.uuidString) }.map(\.identifier)
            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ids)
        }
        #endif
    }
    
    func cancelAllNotifications() {
        #if canImport(UserNotifications)
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        #endif
    }
    
    #if canImport(UserNotifications)
    private func notificationSound(for sound: ReminderSound) -> UNNotificationSound? {
        switch sound {
        case .default: .default
        case .chime: UNNotificationSound(named: UNNotificationSoundName("chime.aiff"))
        case .bell: UNNotificationSound(named: UNNotificationSoundName("bell.aiff"))
        case .alert: UNNotificationSound(named: UNNotificationSoundName("alert.aiff"))
        case .none: nil
        }
    }
    #endif
}
