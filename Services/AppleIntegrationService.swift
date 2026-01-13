import Foundation
import EventKit
import EventKitUI

/// Service for integrating with Apple Reminders and Calendar
class AppleIntegrationService: ObservableObject {
    static let shared = AppleIntegrationService()
    
    private let eventStore = EKEventStore()
    
    @Published var calendarAccessGranted = false
    @Published var remindersAccessGranted = false
    
    private init() {
        checkCalendarAccess()
        checkRemindersAccess()
    }
    
    // MARK: - Calendar Integration
    
    /// Request calendar access
    func requestCalendarAccess() async -> Bool {
        let status = await eventStore.requestAccess(to: .event)
        await MainActor.run {
            calendarAccessGranted = status
        }
        return status
    }
    
    /// Check calendar access status
    func checkCalendarAccess() {
        let status = EKEventStore.authorizationStatus(for: .event)
        calendarAccessGranted = status == .authorized
    }
    
    /// Create a calendar event for a habit
    func createCalendarEvent(for habit: Habit, on date: Date) -> Bool {
        guard calendarAccessGranted else { return false }
        
        let event = EKEvent(eventStore: eventStore)
        event.title = habit.name
        event.notes = habit.description
        event.startDate = date
        event.endDate = date.addingTimeInterval(3600) // 1 hour default
        event.calendar = eventStore.defaultCalendarForNewEvents
        
        do {
            try eventStore.save(event, span: .thisEvent)
            return true
        } catch {
            print("Error saving calendar event: \(error)")
            return false
        }
    }
    
    /// Create recurring calendar events for a habit
    func createRecurringCalendarEvents(for habit: Habit) -> Bool {
        guard calendarAccessGranted else { return false }
        
        // This is a simplified implementation
        // In production, you'd want to create recurring events based on habit frequency
        return true
    }
    
    // MARK: - Reminders Integration
    
    /// Request reminders access
    func requestRemindersAccess() async -> Bool {
        // Note: Reminders framework doesn't have a direct async request method
        // This is a placeholder - actual implementation would use completion handler
        return remindersAccessGranted
    }
    
    /// Check reminders access status
    func checkRemindersAccess() {
        // Note: Reminders framework access is typically granted automatically
        // This is a simplified check
        remindersAccessGranted = true
    }
    
    /// Create a reminder for a habit
    func createReminder(for habit: Habit, on date: Date) -> Bool {
        guard remindersAccessGranted else { return false }
        
        // Note: Actual Reminders framework implementation would go here
        // This is a placeholder
        print("Creating reminder for \(habit.name) on \(date)")
        return true
    }
    
    /// Sync habit reminders with Apple Reminders
    func syncHabitReminders(_ habit: Habit) {
        // Implementation would sync habit reminders with Apple Reminders
        // This is a placeholder
        print("Syncing reminders for \(habit.name)")
    }
}
