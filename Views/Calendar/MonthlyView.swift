import SwiftUI

struct MonthlyView: View {
    @StateObject private var viewModel = CalendarViewModel()
    @State private var selectedDate = Date()
    
    var body: some View {
        VStack(spacing: 0) {
            // Month selector
            HStack {
                Button(action: { changeMonth(by: -1) }) {
                    Image(systemName: "chevron.left")
                }
                
                Spacer()
                
                Text(monthText)
                    .font(.headline)
                
                Spacer()
                
                Button(action: { changeMonth(by: 1) }) {
                    Image(systemName: "chevron.right")
                }
            }
            .padding()
            
            // Calendar
            ScrollView {
                VStack(spacing: 16) {
                    // Calendar grid
                    let monthDates = viewModel.getMonthDates(containing: selectedDate)
                    
                    // Weekday headers
                    HStack(spacing: 0) {
                        ForEach(["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"], id: \.self) { day in
                            Text(day)
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .padding(.horizontal)
                    
                    // Calendar grid
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 4) {
                        ForEach(monthDates, id: \.self) { date in
                            MonthlyDayCell(
                                date: date,
                                habits: viewModel.habits,
                                isSelected: Calendar.current.isDate(date, inSameDayAs: selectedDate),
                                isCurrentMonth: Calendar.current.isDate(date, equalTo: selectedDate, toGranularity: .month)
                            )
                            .onTapGesture {
                                selectedDate = date
                            }
                        }
                    }
                    .padding()
                    
                    // Habits summary
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Habits Summary")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        ForEach(viewModel.habits) { habit in
                            MonthlyHabitSummary(
                                habit: habit,
                                month: viewModel.getMonthDates(containing: selectedDate)
                            )
                        }
                    }
                }
            }
        }
        .navigationTitle("Monthly View")
    }
    
    private var monthText: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: selectedDate)
    }
    
    private func changeMonth(by months: Int) {
        if let newDate = Calendar.current.date(byAdding: .month, value: months, to: selectedDate) {
            selectedDate = newDate
        }
    }
}

struct MonthlyDayCell: View {
    let date: Date
    let habits: [Habit]
    let isSelected: Bool
    let isCurrentMonth: Bool
    @StateObject private var habitService = HabitService.shared
    
    private var completedHabits: [Habit] {
        habits.filter { habitService.isHabitCompleted(habitId: $0.id, date: date) }
    }
    
    var body: some View {
        VStack(spacing: 2) {
            Text("\(Calendar.current.component(.day, from: date))")
                .font(.system(size: 12, weight: isSelected ? .bold : .regular))
                .foregroundColor(isCurrentMonth ? (isSelected ? .white : .primary) : .secondary)
            
            // Habit indicators
            HStack(spacing: 2) {
                ForEach(Array(completedHabits.prefix(3)), id: \.id) { habit in
                    Circle()
                        .fill(habit.color.color)
                        .frame(width: 4, height: 4)
                }
                
                if completedHabits.count > 3 {
                    Text("+\(completedHabits.count - 3)")
                        .font(.system(size: 8))
                        .foregroundColor(.secondary)
                }
            }
        }
        .frame(width: 40, height: 50)
        .background(isSelected ? Color.blue.opacity(0.3) : Color.clear)
        .cornerRadius(6)
        .opacity(isCurrentMonth ? 1.0 : 0.3)
    }
}

struct MonthlyHabitSummary: View {
    let habit: Habit
    let month: [Date]
    @StateObject private var viewModel = CalendarViewModel()
    
    var body: some View {
        HStack {
            Circle()
                .fill(habit.color.color)
                .frame(width: 12, height: 12)
            
            Text(habit.name)
                .font(.subheadline)
            
            Spacer()
            
            Text("\(viewModel.getCompletionCount(for: habit, in: month)) days")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal)
    }
}

#Preview {
    NavigationView {
        MonthlyView()
    }
}
