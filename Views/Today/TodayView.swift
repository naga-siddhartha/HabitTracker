import SwiftUI

struct TodayView: View {
    @StateObject private var viewModel = CalendarViewModel()
    @StateObject private var habitService = HabitService.shared
    
    private var today = Date()
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Today")
                            .font(.largeTitle)
                            .bold()
                        
                        Text(today.mediumDateString)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    
                    // Completion summary
                    let todayHabits = viewModel.getHabitsForDay(today)
                    let completedCount = todayHabits.filter { viewModel.isHabitCompleted($0, on: today) }.count
                    
                    if !todayHabits.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Progress")
                                .font(.headline)
                                .padding(.horizontal)
                            
                            ProgressView(value: Double(completedCount), total: Double(todayHabits.count))
                                .padding(.horizontal)
                            
                            Text("\(completedCount) of \(todayHabits.count) habits completed")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .padding(.horizontal)
                        }
                        .padding(.vertical)
                    }
                    
                    // Today's habits
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Today's Habits")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        if todayHabits.isEmpty {
                            VStack(spacing: 8) {
                                Image(systemName: "checkmark.circle")
                                    .font(.system(size: 50))
                                    .foregroundColor(.secondary)
                                Text("No habits scheduled for today")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 40)
                        } else {
                            ForEach(todayHabits) { habit in
                                TodayHabitCard(
                                    habit: habit,
                                    isCompleted: viewModel.isHabitCompleted(habit, on: today)
                                )
                                .onTapGesture {
                                    if viewModel.isHabitActive(habit: habit, on: today) {
                                        viewModel.toggleHabitCompletion(habit, on: today)
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                }
            }
            .navigationTitle("Today")
        }
    }
}

struct TodayHabitCard: View {
    let habit: Habit
    let isCompleted: Bool
    @StateObject private var streakService = StreakService.shared
    
    var body: some View {
        HStack(spacing: 16) {
            // Completion button
            Button(action: {}) {
                Image(systemName: isCompleted ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isCompleted ? habit.color.color : .secondary)
                    .font(.title2)
            }
            
            // Icon
            if let iconName = habit.iconName {
                Image(systemName: iconName)
                    .foregroundColor(habit.color.color)
                    .font(.title2)
            } else {
                Circle()
                    .fill(habit.color.color)
                    .frame(width: 40, height: 40)
            }
            
            // Info
            VStack(alignment: .leading, spacing: 4) {
                Text(habit.name)
                    .font(.headline)
                    .strikethrough(isCompleted)
                
                if let description = habit.description {
                    Text(description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                // Streak
                if let streak = streakService.getStreak(for: habit.id), streak.currentStreak > 0 {
                    HStack(spacing: 4) {
                        Image(systemName: "flame.fill")
                            .foregroundColor(.orange)
                            .font(.caption)
                        Text("\(streak.currentStreak) day streak")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Spacer()
        }
        .padding()
        .background(isCompleted ? habit.color.color.opacity(0.1) : Color(UIColor.systemGray6))
        .cornerRadius(12)
    }
}

#Preview {
    TodayView()
}
