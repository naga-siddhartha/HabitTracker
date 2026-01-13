import SwiftUI

struct YearlyView: View {
    @StateObject private var viewModel = CalendarViewModel()
    @State private var selectedYear = Calendar.current.component(.year, from: Date())
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Year selector
                HStack {
                    Button(action: { selectedYear -= 1 }) {
                        Image(systemName: "chevron.left")
                    }
                    
                    Spacer()
                    
                    Text("\(selectedYear)")
                        .font(.largeTitle)
                        .bold()
                    
                    Spacer()
                    
                    Button(action: { selectedYear += 1 }) {
                        Image(systemName: "chevron.right")
                    }
                }
                .padding()
                
                // Year overview
                VStack(spacing: 16) {
                    ForEach(viewModel.habits) { habit in
                        YearlyHabitCard(
                            habit: habit,
                            year: selectedYear
                        )
                    }
                }
                .padding()
            }
        }
        .navigationTitle("Yearly View")
    }
}

struct YearlyHabitCard: View {
    let habit: Habit
    let year: Int
    @StateObject private var viewModel = CalendarViewModel()
    
    private var yearStart: Date {
        var components = DateComponents()
        components.year = year
        components.month = 1
        components.day = 1
        return Calendar.current.date(from: components) ?? Date()
    }
    
    private var yearDates: [Date] {
        viewModel.getYearDates(containing: yearStart)
    }
    
    private var totalCompletions: Int {
        viewModel.getCompletionCount(for: habit, in: yearDates)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                if let iconName = habit.iconName {
                    Image(systemName: iconName)
                        .foregroundColor(habit.color.color)
                        .font(.title2)
                } else {
                    Circle()
                        .fill(habit.color.color)
                        .frame(width: 30, height: 30)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(habit.name)
                        .font(.headline)
                    
                    Text("\(totalCompletions) completions")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            
            // Monthly breakdown
            HStack(spacing: 8) {
                ForEach(yearDates, id: \.self) { monthDate in
                    MonthlyCompletionIndicator(
                        habit: habit,
                        monthDate: monthDate
                    )
                }
            }
        }
        .padding()
        .background(Color(UIColor.systemGray6))
        .cornerRadius(12)
    }
}

struct MonthlyCompletionIndicator: View {
    let habit: Habit
    let monthDate: Date
    @StateObject private var viewModel = CalendarViewModel()
    
    private var monthDates: [Date] {
        viewModel.getMonthDates(containing: monthDate)
    }
    
    private var completionCount: Int {
        viewModel.getCompletionCount(for: habit, in: monthDates)
    }
    
    private var maxPossible: Int {
        monthDates.filter { date in
            viewModel.isHabitActive(habit: habit, on: date)
        }.count
    }
    
    private var completionRatio: Double {
        guard maxPossible > 0 else { return 0 }
        return Double(completionCount) / Double(maxPossible)
    }
    
    var body: some View {
        VStack(spacing: 4) {
            Text(monthAbbreviation)
                .font(.system(size: 8))
                .foregroundColor(.secondary)
            
            RoundedRectangle(cornerRadius: 4)
                .fill(habit.color.color.opacity(completionRatio))
                .frame(width: 20, height: 30)
            
            Text("\(completionCount)")
                .font(.system(size: 8))
                .foregroundColor(.secondary)
        }
    }
    
    private var monthAbbreviation: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM"
        return formatter.string(from: monthDate)
    }
}

#Preview {
    NavigationView {
        YearlyView()
    }
}
