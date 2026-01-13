import Foundation
import UserNotifications

/// Service for managing habit reminders and notifications
class NotificationService: ObservableObject {
    static let shared = NotificationService()
    
    private let habitService = HabitService.shared
    
    private init() {
        requestAuthorization()
    }
    
    /// Request notification authorization
    func requestAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error = error {
                print("Notification authorization error: \(error)")
            }
        }
    }
    
    /// Schedule reminders for a habit
    func scheduleReminders(for habit: Habit) {
        // Remove existing notifications for this habit
        removeReminders(for: habit.id)
        
        guard !habit.reminderTimes.isEmpty else { return }
        
        let calendar = Calendar.current
        
        for reminderTime in habit.reminderTimes {
            let timeComponents = calendar.dateComponents([.hour, .minute], from: reminderTime)
            
            // Create notification content
            let content = UNMutableNotificationContent()
            content.title = "Habit Reminder"
            content.body = "Time to work on: \(habit.name)"
            content.sound = .default
            content.categoryIdentifier = "HABIT_REMINDER"
            content.userInfo = ["habitId": habit.id.uuidString]
            
            // Create trigger based on habit frequency
            var dateComponents = DateComponents()
            dateComponents.hour = timeComponents.hour
            dateComponents.minute = timeComponents.minute
            
            switch habit.frequency {
            case .daily:
                // Daily reminder
                let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
                let request = UNNotificationRequest(
                    identifier: "\(habit.id.uuidString)-\(timeComponents.hour ?? 0)-\(timeComponents.minute ?? 0)",
                    content: content,
                    trigger: trigger
                )
                UNUserNotificationCenter.current().add(request)
                
            case .weekly:
                // Weekly reminder on active days
                if let activeDays = habit.activeDays, !activeDays.isEmpty {
                    for weekday in activeDays {
                        dateComponents.weekday = weekday.rawValue
                        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
                        let request = UNNotificationRequest(
                            identifier: "\(habit.id.uuidString)-\(weekday.rawValue)-\(timeComponents.hour ?? 0)-\(timeComponents.minute ?? 0)",
                            content: content,
                            trigger: trigger
                        )
                        UNUserNotificationCenter.current().add(request)
                    }
                } else {
                    // All days of week
                    for weekday in Weekday.allCases {
                        dateComponents.weekday = weekday.rawValue
                        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
                        let request = UNNotificationRequest(
                            identifier: "\(habit.id.uuidString)-\(weekday.rawValue)-\(timeComponents.hour ?? 0)-\(timeComponents.minute ?? 0)",
                            content: content,
                            trigger: trigger
                        )
                        UNUserNotificationCenter.current().add(request)
                    }
                }
                
            case .custom:
                // For custom patterns, schedule for all days (pattern logic handled elsewhere)
                // Or schedule based on pattern analysis
                for weekday in Weekday.allCases {
                    dateComponents.weekday = weekday.rawValue
                    let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
                    let request = UNNotificationRequest(
                        identifier: "\(habit.id.uuidString)-\(weekday.rawValue)-\(timeComponents.hour ?? 0)-\(timeComponents.minute ?? 0)",
                        content: content,
                        trigger: trigger
                    )
                    UNUserNotificationCenter.current().add(request)
                }
            }
        }
    }
    
    /// Remove all reminders for a habit
    func removeReminders(for habitId: UUID) {
        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
            let identifiers = requests
                .filter { $0.content.userInfo["habitId"] as? String == habitId.uuidString }
                .map { $0.identifier }
            
            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: identifiers)
        }
    }
    
    /// Update reminders for all habits
    func updateAllReminders() {
        let habits = habitService.getActiveHabits()
        for habit in habits {
            scheduleReminders(for: habit)
        }
    }
    
    /// Cancel all notifications
    func cancelAllNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }
}
