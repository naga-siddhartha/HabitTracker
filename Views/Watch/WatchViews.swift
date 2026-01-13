import SwiftUI
import SwiftData

#if os(watchOS)
struct WatchMainView: View {
    var body: some View {
        NavigationStack {
            WatchTodayView()
        }
    }
}

struct WatchTodayView: View {
    @Query(filter: #Predicate<Habit> { !$0.isArchived }) private var habits: [Habit]
    private let today = Date.now
    
    private var todayHabits: [Habit] {
        habits.filter { $0.isActive(on: today) }
    }
    
    var body: some View {
        List(todayHabits) { habit in
            WatchHabitRow(habit: habit, date: today)
        }
        .navigationTitle("Today")
    }
}

struct WatchHabitRow: View {
    @Bindable var habit: Habit
    let date: Date
    
    private var isCompleted: Bool { habit.isCompleted(on: date) }
    
    var body: some View {
        Button {
            HabitStore.shared.toggleCompletion(for: habit, on: date)
        } label: {
            HStack {
                Image(systemName: isCompleted ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(isCompleted ? habit.color.color : .secondary)
                
                Text(habit.name)
                    .strikethrough(isCompleted)
            }
        }
        .buttonStyle(.plain)
    }
}
#endif
