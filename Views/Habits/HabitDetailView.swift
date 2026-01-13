import SwiftUI

struct HabitDetailView: View {
    let habit: Habit
    @StateObject private var habitService = HabitService.shared
    @StateObject private var streakService = StreakService.shared
    @StateObject private var calendarViewModel = CalendarViewModel()
    @State private var showingEditView = false
    @State private var selectedDate = Date()
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header
                HStack {
                    if let iconName = habit.iconName {
                        Image(systemName: iconName)
                            .foregroundColor(habit.color.color)
                            .font(.system(size: 60))
                    } else {
                        Circle()
                            .fill(habit.color.color)
                            .frame(width: 60, height: 60)
                    }
                    
                    VStack(alignment: .leading) {
                        Text(habit.name)
                            .font(.largeTitle)
                            .bold()
                        
                        if let description = habit.description {
                            Text(description)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Spacer()
                }
                .padding()
                
                // Streak Info
                if let streak = streakService.getStreak(for: habit.id) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Streak")
                            .font(.headline)
                        
                        HStack {
                            VStack(alignment: .leading) {
                                Text("Current")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text("\(streak.currentStreak)")
                                    .font(.title)
                                    .bold()
                            }
                            
                            Spacer()
                            
                            VStack(alignment: .trailing) {
                                Text("Longest")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text("\(streak.longestStreak)")
                                    .font(.title)
                                    .bold()
                            }
                        }
                    }
                    .padding()
                    .background(Color(UIColor.systemGray6))
                    .cornerRadius(12)
                    .padding(.horizontal)
                }
                
                // Today's Status
                VStack(alignment: .leading, spacing: 12) {
                    Text("Today")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    Button(action: {
                        calendarViewModel.toggleHabitCompletion(habit, on: Date())
                    }) {
                        HStack {
                            Image(systemName: habitService.isHabitCompleted(habitId: habit.id, date: Date()) ? "checkmark.circle.fill" : "circle")
                                .font(.title2)
                            Text(habitService.isHabitCompleted(habitId: habit.id, date: Date()) ? "Completed" : "Mark as Complete")
                                .font(.headline)
                            Spacer()
                        }
                        .padding()
                        .background(habitService.isHabitCompleted(habitId: habit.id, date: Date()) ? habit.color.color.opacity(0.2) : Color(UIColor.systemGray6))
                        .foregroundColor(habitService.isHabitCompleted(habitId: habit.id, date: Date()) ? habit.color.color : .primary)
                        .cornerRadius(12)
                    }
                    .padding(.horizontal)
                }
                
                // Calendar View
                VStack(alignment: .leading, spacing: 12) {
                    Text("Calendar")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    // Simple month view
                    MonthCalendarView(habit: habit, selectedDate: $selectedDate)
                }
            }
        }
        .navigationTitle(habit.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Edit") {
                    showingEditView = true
                }
            }
        }
        .sheet(isPresented: $showingEditView) {
            AddEditHabitView(habit: habit)
        }
    }
}

#Preview {
    NavigationView {
        HabitDetailView(habit: Habit(name: "Morning Run", description: "Run 5km every morning"))
    }
}
