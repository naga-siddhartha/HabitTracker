import SwiftUI

struct WeeklyView: View {
    @StateObject private var viewModel = CalendarViewModel()
    @State private var selectedDate = Date()
    
    var body: some View {
        VStack(spacing: 0) {
            // Week selector
            HStack {
                Button(action: { changeWeek(by: -1) }) {
                    Image(systemName: "chevron.left")
                }
                
                Spacer()
                
                Text(weekRangeText)
                    .font(.headline)
                
                Spacer()
                
                Button(action: { changeWeek(by: 1) }) {
                    Image(systemName: "chevron.right")
                }
            }
            .padding()
            
            // Week grid
            ScrollView {
                VStack(spacing: 12) {
                    ForEach(viewModel.habits) { habit in
                        WeeklyHabitRow(
                            habit: habit,
                            weekDates: viewModel.getWeekDates(containing: selectedDate)
                        )
                    }
                }
                .padding()
            }
        }
        .navigationTitle("Weekly View")
    }
    
    private var weekDates: [Date] {
        viewModel.getWeekDates(containing: selectedDate)
    }
    
    private var weekRangeText: String {
        guard let firstDate = weekDates.first,
              let lastDate = weekDates.last else {
            return ""
        }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        
        if Calendar.current.isDate(firstDate, equalTo: lastDate, toGranularity: .month) {
            return "\(formatter.string(from: firstDate)) - \(Calendar.current.component(.day, from: lastDate)), \(formatter.string(from: lastDate).components(separatedBy: " ").first ?? "")"
        } else {
            return "\(formatter.string(from: firstDate)) - \(formatter.string(from: lastDate))"
        }
    }
    
    private func changeWeek(by weeks: Int) {
        if let newDate = Calendar.current.date(byAdding: .weekOfYear, value: weeks, to: selectedDate) {
            selectedDate = newDate
        }
    }
}

struct WeeklyHabitRow: View {
    let habit: Habit
    let weekDates: [Date]
    @StateObject private var viewModel = CalendarViewModel()
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Habit header
            HStack {
                if let iconName = habit.iconName {
                    Image(systemName: iconName)
                        .foregroundColor(habit.color.color)
                } else {
                    Circle()
                        .fill(habit.color.color)
                        .frame(width: 20, height: 20)
                }
                
                Text(habit.name)
                    .font(.headline)
                
                Spacer()
                
                Text("\(viewModel.getCompletionCount(for: habit, in: weekDates))/\(weekDates.count)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            // Week grid
            HStack(spacing: 4) {
                ForEach(weekDates, id: \.self) { date in
                    WeeklyDayCell(
                        date: date,
                        habit: habit,
                        isCompleted: viewModel.isHabitCompleted(habit, on: date),
                        isActive: viewModel.isHabitActive(habit: habit, on: date)
                    )
                    .onTapGesture {
                        if viewModel.isHabitActive(habit: habit, on: date) {
                            viewModel.toggleHabitCompletion(habit, on: date)
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color(UIColor.systemGray6))
        .cornerRadius(12)
    }
}

struct WeeklyDayCell: View {
    let date: Date
    let habit: Habit
    let isCompleted: Bool
    let isActive: Bool
    
    private var dayName: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "E"
        return formatter.string(from: date)
    }
    
    private var dayNumber: String {
        "\(Calendar.current.component(.day, from: date))"
    }
    
    var body: some View {
        VStack(spacing: 4) {
            Text(dayName)
                .font(.caption2)
                .foregroundColor(.secondary)
            
            Text(dayNumber)
                .font(.caption)
                .bold()
            
            if isActive {
                Circle()
                    .fill(isCompleted ? habit.color.color : Color(UIColor.systemGray4))
                    .frame(width: 8, height: 8)
            } else {
                Circle()
                    .fill(Color.clear)
                    .frame(width: 8, height: 8)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(isCompleted ? habit.color.color.opacity(0.2) : Color.clear)
        .cornerRadius(8)
    }
}

#Preview {
    NavigationView {
        WeeklyView()
    }
}
