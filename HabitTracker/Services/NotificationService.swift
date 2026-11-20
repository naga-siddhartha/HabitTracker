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
    
    /// Permission is requested by `rescheduleAll` the first time there is a reminder to schedule,
    /// not when this object is first touched, so launching the app never triggers a prompt.
    private init() {}
    
    func requestAuthorization() {
        #if canImport(UserNotifications)
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in }
        #endif
    }
    
    /// iOS keeps at most 64 pending local notifications per app and silently drops the rest.
    static let maxPendingRequests = 64

    /// Replace every pending reminder with a fresh set built from `habits`.
    ///
    /// Rebuilding the whole set in one place fixes two problems with per-habit scheduling:
    /// 1. Removing a habit's old reminders was asynchronous, so it could run after the new ones
    ///    were added and delete them.
    /// 2. With several "every N hours" or weekly habits, the total went past iOS's 64 limit and
    ///    reminders vanished at random. Here fixed-time reminders win, then interval slots are
    ///    shared round-robin so every habit keeps its earliest reminders.
    func rescheduleAll(_ habits: [NotificationHabit]) {
        #if canImport(UserNotifications)
        let center = UNUserNotificationCenter.current()
        // Respect the app's Notifications toggle (defaults to true when unset).
        if UserDefaults.standard.object(forKey: "notificationsEnabled") as? Bool == false {
            center.removeAllPendingNotificationRequests()
            return
        }
        let requests = Self.buildRequests(for: habits)
        guard !requests.isEmpty else {
            center.removeAllPendingNotificationRequests()
            return
        }
        Task {
            switch await center.notificationSettings().authorizationStatus {
            case .notDetermined:
                let granted = (try? await center.requestAuthorization(options: [.alert, .sound, .badge])) ?? false
                if granted { Self.replaceAll(with: requests) }
            case .authorized, .provisional, .ephemeral:
                Self.replaceAll(with: requests)
            case .denied:
                break
            @unknown default:
                break
            }
        }
        #endif
    }

    #if canImport(UserNotifications)
    nonisolated private static func replaceAll(with requests: [UNNotificationRequest]) {
        let center = UNUserNotificationCenter.current()
        // The notification center applies calls in order, so the removal can't land after the adds.
        center.removeAllPendingNotificationRequests()
        for request in requests {
            center.add(request)
        }
    }

    /// Builds the prioritized, capped request list. Internal (not private) for unit tests.
    static func buildRequests(for habits: [NotificationHabit], limit: Int = maxPendingRequests) -> [UNNotificationRequest] {
        let calendar = Calendar.current
        var planned: [(priority: Int, order: Int, request: UNNotificationRequest)] = []

        func add(_ request: UNNotificationRequest, priority: Int) {
            planned.append((priority, planned.count, request))
        }

        for habit in habits {
            // Specific weekdays only when the habit isn't effectively every day.
            let weekdays: [Weekday]? = {
                guard habit.frequency == .weekly, !habit.activeDays.isEmpty,
                      habit.activeDays.count < Weekday.allCases.count else { return nil }
                return habit.activeDays.sorted { $0.rawValue < $1.rawValue }
            }()

            if habit.reminderIntervalMinutes > 0 {
                let content = makeContent(
                    habit: habit,
                    title: habit.reminderNames.first ?? "Reminder",
                    sound: habit.reminderSounds.first ?? .default
                )
                guard let startTime = habit.reminderTimes.first else {
                    // No start time: repeat every N minutes from now.
                    let seconds = max(60, TimeInterval(habit.reminderIntervalMinutes * 60))
                    let trigger = UNTimeIntervalNotificationTrigger(timeInterval: seconds, repeats: true)
                    add(UNNotificationRequest(identifier: habit.id.uuidString, content: content, trigger: trigger), priority: 1)
                    continue
                }
                let start = calendar.dateComponents([.hour, .minute], from: startTime)
                let startMinutes = (start.hour ?? 0) * 60 + (start.minute ?? 0)
                let endMinutes: Int = {
                    guard let end = habit.reminderEndTime else { return 24 * 60 - 1 }
                    let c = calendar.dateComponents([.hour, .minute], from: end)
                    return (c.hour ?? 23) * 60 + (c.minute ?? 59)
                }()
                var slot = 0
                var minutes = startMinutes
                while slot < 24 && minutes <= endMinutes && minutes < 24 * 60 {
                    let days: [Weekday?] = weekdays.map { $0.map(Optional.some) } ?? [nil]
                    for day in days {
                        var comps = DateComponents()
                        comps.hour = minutes / 60
                        comps.minute = minutes % 60
                        comps.weekday = day?.rawValue
                        let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: true)
                        let suffix = day.map { "-\($0.rawValue)" } ?? ""
                        add(UNNotificationRequest(identifier: "\(habit.id.uuidString)-interval-\(slot)\(suffix)", content: content, trigger: trigger),
                            priority: 1 + slot)
                    }
                    slot += 1
                    minutes += habit.reminderIntervalMinutes
                }
                continue
            }

            for (index, time) in habit.reminderTimes.enumerated() {
                let title = habit.reminderNames.indices.contains(index) ? habit.reminderNames[index] : "Reminder"
                let sound = habit.reminderSounds.indices.contains(index) ? habit.reminderSounds[index] : .default
                let content = makeContent(habit: habit, title: title, sound: sound)
                let t = calendar.dateComponents([.hour, .minute], from: time)
                let days: [Weekday?] = weekdays.map { $0.map(Optional.some) } ?? [nil]
                for day in days {
                    var comps = DateComponents()
                    comps.hour = t.hour
                    comps.minute = t.minute
                    comps.weekday = day?.rawValue
                    let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: true)
                    let suffix = day.map { "-\($0.rawValue)" } ?? ""
                    add(UNNotificationRequest(identifier: "\(habit.id.uuidString)-\(index)\(suffix)", content: content, trigger: trigger),
                        priority: 0)
                }
            }
        }

        let sorted = planned.sorted { ($0.priority, $0.order) < ($1.priority, $1.order) }
        #if DEBUG
        if sorted.count > limit {
            print("[Notifications] \(sorted.count) reminders requested, keeping \(limit) (iOS limit)")
        }
        #endif
        return sorted.prefix(limit).map(\.request)
    }

    private static func makeContent(habit: NotificationHabit, title: String, sound: ReminderSound) -> UNMutableNotificationContent {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = "Time to work on: \(habit.name)"
        content.sound = notificationSound(for: sound)
        content.userInfo = ["habitId": habit.id.uuidString]
        return content
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
    private static func notificationSound(for sound: ReminderSound) -> UNNotificationSound? {
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
