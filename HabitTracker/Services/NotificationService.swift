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
    /// When greater than zero, schedule a repeating reminder every N minutes instead of fixed times.
    let reminderIntervalMinutes: Int
    /// End time for repeating reminders (stop sending after this time). Nil means remind until midnight.
    let reminderEndTime: Date?
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
        let hasSpecificTimes = !habit.reminderTimes.isEmpty
        let hasRepeatingInterval = habit.reminderIntervalMinutes > 0
        guard hasSpecificTimes || hasRepeatingInterval else { return }
        // Respect the app's Notifications toggle (defaults to true when unset).
        if UserDefaults.standard.object(forKey: "notificationsEnabled") as? Bool == false { return }
        removeReminders(for: habit.id)

        UNUserNotificationCenter.current().getNotificationSettings { [self] settings in
            switch settings.authorizationStatus {
            case .notDetermined:
                requestAuthorizationAndSchedule(habit: habit)
            case .authorized, .provisional, .ephemeral:
                performScheduleReminders(for: habit)
            case .denied:
                break
            @unknown default:
                break
            }
        }
        #endif
    }

    #if canImport(UserNotifications)
    private func requestAuthorizationAndSchedule(habit: NotificationHabit) {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { [self] granted, _ in
            guard granted else { return }
            performScheduleReminders(for: habit)
        }
    }

    private func performScheduleReminders(for habit: NotificationHabit) {
        let calendar = Calendar.current

        // Interval-based reminders (e.g. "every 2 hours from 8 AM to 6 PM")
        if habit.reminderIntervalMinutes > 0 {
            let intervalMinutes = habit.reminderIntervalMinutes
            let reminderName = habit.reminderNames.first ?? "Reminder"
            let sound = habit.reminderSounds.first ?? .default

            let content = UNMutableNotificationContent()
            content.title = reminderName
            content.body = "Time to work on: \(habit.name)"
            content.sound = notificationSound(for: sound)
            content.userInfo = ["habitId": habit.id.uuidString]

            if let startTime = habit.reminderTimes.first {
                let startComponents = calendar.dateComponents([.hour, .minute], from: startTime)
                let startMinutesOfDay = (startComponents.hour ?? 0) * 60 + (startComponents.minute ?? 0)
                
                // Calculate end time in minutes
                let endMinutesOfDay: Int
                if let endTime = habit.reminderEndTime {
                    let endComponents = calendar.dateComponents([.hour, .minute], from: endTime)
                    endMinutesOfDay = (endComponents.hour ?? 23) * 60 + (endComponents.minute ?? 59)
                } else {
                    endMinutesOfDay = 24 * 60 // midnight
                }
                
                let maxTriggersPerDay = 24
                var slotIndex = 0
                var minutesOfDay = startMinutesOfDay
                while slotIndex < maxTriggersPerDay && minutesOfDay <= endMinutesOfDay {
                    var dateComponents = DateComponents()
                    dateComponents.hour = minutesOfDay / 60
                    dateComponents.minute = minutesOfDay % 60
                    let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
                    let request = UNNotificationRequest(
                        identifier: "\(habit.id.uuidString)-interval-\(slotIndex)",
                        content: content,
                        trigger: trigger
                    )
                    UNUserNotificationCenter.current().add(request)
                    slotIndex += 1
                    minutesOfDay += intervalMinutes
                }
            } else {
                // No start time: repeat from now (e.g. every 2 hours)
                let intervalSeconds = max(60, TimeInterval(intervalMinutes * 60))
                let trigger = UNTimeIntervalNotificationTrigger(timeInterval: intervalSeconds, repeats: true)
                let request = UNNotificationRequest(
                    identifier: habit.id.uuidString,
                    content: content,
                    trigger: trigger
                )
                UNUserNotificationCenter.current().add(request)
            }
            return
        }

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
    }
    #endif

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
