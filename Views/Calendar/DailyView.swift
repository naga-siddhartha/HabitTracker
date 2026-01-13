import SwiftUI

struct DailyView: View {
    @StateObject private var viewModel = CalendarViewModel()
    @State private var selectedDate = Date()
    
    var body: some View {
        VStack(spacing: 0) {
            // Date selector
            DatePicker("Select Date", selection: $selectedDate, displayedComponents: .date)
                .datePickerStyle(.compact)
                .padding()
            
            // Habits for the day
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(viewModel.getHabitsForDay(selectedDate)) { habit in
                        DailyHabitCard(
                            habit: habit,
                            date: selectedDate,
                            isCompleted: viewModel.isHabitCompleted(habit, on: selectedDate)
                        )
                        .onTapGesture {
                            if viewModel.isHabitActive(habit: habit, on: selectedDate) {
                                viewModel.toggleHabitCompletion(habit, on: selectedDate)
                            }
                        }
                    }
                }
                .padding()
            }
        }
        .navigationTitle("Daily View")
    }
}

struct DailyHabitCard: View {
    let habit: Habit
    let date: Date
    let isCompleted: Bool
    
    var body: some View {
        HStack {
            // Icon
            if let iconName = habit.iconName {
                Image(systemName: iconName)
                    .foregroundColor(habit.color.color)
                    .font(.title)
            } else {
                Circle()
                    .fill(habit.color.color)
                    .frame(width: 50, height: 50)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(habit.name)
                    .font(.headline)
                
                if let description = habit.description {
                    Text(description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            // Completion indicator
            Image(systemName: isCompleted ? "checkmark.circle.fill" : "circle")
                .foregroundColor(isCompleted ? habit.color.color : .secondary)
                .font(.title2)
        }
        .padding()
        .background(isCompleted ? habit.color.color.opacity(0.1) : Color(UIColor.systemGray6))
        .cornerRadius(12)
    }
}

#Preview {
    NavigationView {
        DailyView()
    }
}
