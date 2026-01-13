import SwiftUI

struct MonthCalendarView: View {
    let habit: Habit
    @Binding var selectedDate: Date
    @StateObject private var habitService = HabitService.shared
    @StateObject private var calendarViewModel = CalendarViewModel()
    
    var body: some View {
        let monthDates = calendarViewModel.getMonthDates(containing: selectedDate)
        let calendar = Calendar.current
        
        VStack(spacing: 0) {
            // Month header
            HStack {
                Button(action: { changeMonth(by: -1) }) {
                    Image(systemName: "chevron.left")
                }
                
                Spacer()
                
                Text(selectedDate.mediumDateString)
                    .font(.headline)
                
                Spacer()
                
                Button(action: { changeMonth(by: 1) }) {
                    Image(systemName: "chevron.right")
                }
            }
            .padding()
            
            // Weekday headers
            HStack(spacing: 0) {
                ForEach(["S", "M", "T", "W", "T", "F", "S"], id: \.self) { day in
                    Text(day)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.horizontal)
            
            // Calendar grid
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 8) {
                ForEach(monthDates, id: \.self) { date in
                    CalendarDayView(
                        date: date,
                        habit: habit,
                        isSelected: calendar.isDate(date, inSameDayAs: selectedDate),
                        isCurrentMonth: calendar.isDate(date, equalTo: selectedDate, toGranularity: .month)
                    )
                    .onTapGesture {
                        selectedDate = date
                        if calendarViewModel.isHabitActive(habit: habit, on: date) {
                            calendarViewModel.toggleHabitCompletion(habit, on: date)
                        }
                    }
                }
            }
            .padding()
        }
        .background(Color(UIColor.systemBackground))
        .cornerRadius(12)
        .padding(.horizontal)
    }
    
    private func changeMonth(by months: Int) {
        if let newDate = Calendar.current.date(byAdding: .month, value: months, to: selectedDate) {
            selectedDate = newDate
        }
    }
}

struct CalendarDayView: View {
    let date: Date
    let habit: Habit
    let isSelected: Bool
    let isCurrentMonth: Bool
    @StateObject private var habitService = HabitService.shared
    @StateObject private var calendarViewModel = CalendarViewModel()
    
    private var isCompleted: Bool {
        habitService.isHabitCompleted(habitId: habit.id, date: date)
    }
    
    private var isActive: Bool {
        calendarViewModel.isHabitActive(habit: habit, on: date)
    }
    
    var body: some View {
        VStack(spacing: 4) {
            Text("\(Calendar.current.component(.day, from: date))")
                .font(.system(size: 14, weight: isSelected ? .bold : .regular))
                .foregroundColor(isCurrentMonth ? (isSelected ? .white : .primary) : .secondary)
            
            if isActive {
                Circle()
                    .fill(isCompleted ? habit.color.color : Color(UIColor.systemGray4))
                    .frame(width: 6, height: 6)
            }
        }
        .frame(width: 40, height: 40)
        .background(isSelected ? habit.color.color : Color.clear)
        .cornerRadius(8)
        .opacity(isCurrentMonth ? 1.0 : 0.3)
    }
}
