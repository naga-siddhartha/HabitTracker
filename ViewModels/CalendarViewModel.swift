import Foundation
import Combine
import SwiftUI

class CalendarViewModel: ObservableObject {
    @Published var selectedDate: Date = Date()
    @Published var currentView: CalendarViewType = .monthly
    @Published var habits: [Habit] = []
    @Published var entries: [HabitEntry] = []
    
    private let habitService = HabitService.shared
    private var cancellables = Set<AnyCancellable>()
    
    enum CalendarViewType {
        case daily
        case weekly
        case monthly
        case yearly
    }
    
    init() {
        // Subscribe to updates
        habitService.$habits
            .receive(on: DispatchQueue.main)
            .assign(to: \.habits, on: self)
            .store(in: &cancellables)
        
        habitService.$entries
            .receive(on: DispatchQueue.main)
            .assign(to: \.entries, on: self)
            .store(in: &cancellables)
    }
    
    // MARK: - Daily View
    
    func getHabitsForDay(_ date: Date) -> [Habit] {
        return habits.filter { habit in
            habitService.isHabitActive(habit: habit, on: date)
        }
    }
    
    func isHabitCompleted(_ habit: Habit, on date: Date) -> Bool {
        return habitService.isHabitCompleted(habitId: habit.id, date: date)
    }
    
    // MARK: - Weekly View
    
    func getWeekDates(containing date: Date) -> [Date] {
        guard let weekStart = date.startOfWeek else { return [] }
        let calendar = Calendar.current
        var dates: [Date] = []
        
        for dayOffset in 0..<7 {
            if let dayDate = calendar.date(byAdding: .day, value: dayOffset, to: weekStart) {
                dates.append(dayDate)
            }
        }
        
        return dates
    }
    
    func getCompletionCount(for habit: Habit, in week: [Date]) -> Int {
        return week.filter { date in
            habitService.isHabitCompleted(habitId: habit.id, date: date)
        }.count
    }
    
    // MARK: - Monthly View
    
    func getMonthDates(containing date: Date) -> [Date] {
        guard let monthStart = date.startOfMonth else { return [] }
        let calendar = Calendar.current
        var dates: [Date] = []
        
        // Get first day of month
        let firstDay = monthStart
        
        // Get number of days in month
        guard let daysInMonth = calendar.range(of: .day, in: .month, for: date)?.count else {
            return []
        }
        
        // Get first weekday of month (1 = Sunday, 7 = Saturday)
        let firstWeekday = calendar.component(.weekday, from: firstDay)
        let startOffset = firstWeekday - 1
        
        // Add padding days from previous month
        for i in 0..<startOffset {
            if let prevDate = calendar.date(byAdding: .day, value: -(startOffset - i), to: firstDay) {
                dates.append(prevDate)
            }
        }
        
        // Add days of current month
        for day in 0..<daysInMonth {
            if let dayDate = calendar.date(byAdding: .day, value: day, to: firstDay) {
                dates.append(dayDate)
            }
        }
        
        // Fill remaining days to complete 6 weeks (42 days)
        let remainingDays = 42 - dates.count
        if let lastDate = dates.last {
            for day in 1...remainingDays {
                if let nextDate = calendar.date(byAdding: .day, value: day, to: lastDate) {
                    dates.append(nextDate)
                }
            }
        }
        
        return dates
    }
    
    func getCompletionCount(for habit: Habit, in month: [Date]) -> Int {
        let monthStart = month.first?.startOfMonth ?? Date()
        let monthEnd = monthStart.endOfMonth ?? Date()
        
        return habitService.getEntries(for: habit.id, from: monthStart, to: monthEnd).count
    }
    
    // MARK: - Yearly View
    
    func getYearDates(containing date: Date) -> [Date] {
        guard let yearStart = date.startOfYear else { return [] }
        let calendar = Calendar.current
        var dates: [Date] = []
        
        for monthOffset in 0..<12 {
            if let monthDate = calendar.date(byAdding: .month, value: monthOffset, to: yearStart) {
                dates.append(monthDate)
            }
        }
        
        return dates
    }
    
    func getCompletionCount(for habit: Habit, in year: [Date]) -> Int {
        guard let yearStart = year.first?.startOfYear,
              let yearEnd = yearStart.endOfYear else {
            return 0
        }
        
        return habitService.getEntries(for: habit.id, from: yearStart, to: yearEnd).count
    }
    
    // MARK: - Actions
    
    func toggleHabitCompletion(_ habit: Habit, on date: Date) {
        habitService.toggleHabitCompletion(habitId: habit.id, date: date)
        StreakService.shared.updateStreak(for: habit.id)
    }
    
    func selectDate(_ date: Date) {
        selectedDate = date
    }
    
    func changeView(to viewType: CalendarViewType) {
        currentView = viewType
    }
}
