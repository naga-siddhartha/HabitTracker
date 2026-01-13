import SwiftUI
import SwiftData

struct DailyView: View {
    @Query(filter: #Predicate<Habit> { !$0.isArchived }) private var habits: [Habit]
    @State private var selectedDate = Date.now
    
    private var activeHabits: [Habit] {
        habits.filter { $0.isActive(on: selectedDate) }
    }
    
    var body: some View {
        VStack {
            DatePicker("Date", selection: $selectedDate, displayedComponents: .date)
                .datePickerStyle(.compact)
                .padding()
            
            List(activeHabits) { habit in
                DailyHabitRow(habit: habit, date: selectedDate)
            }
        }
        .navigationTitle("Daily")
    }
}

struct DailyHabitRow: View {
    @Bindable var habit: Habit
    let date: Date
    
    private var isCompleted: Bool { habit.isCompleted(on: date) }
    
    var body: some View {
        Button {
            withAnimation(.snappy(duration: 0.3)) {
                HabitStore.shared.toggleCompletion(for: habit, on: date)
            }
        } label: {
            HStack {
                if let iconName = habit.iconName {
                    Image(systemName: iconName).foregroundStyle(habit.color.color).font(.title2)
                } else {
                    Circle().fill(habit.color.color).frame(width: 30, height: 30)
                }
                
                Text(habit.name).strikethrough(isCompleted)
                Spacer()
                Image(systemName: isCompleted ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(isCompleted ? habit.color.color : .secondary)
                    .contentTransition(.symbolEffect(.replace))
            }
            .padding(.vertical, 4)
            .background(isCompleted ? habit.color.color.opacity(0.1) : Color.systemGray6)
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
        .sensoryFeedback(.success, trigger: isCompleted)
    }
}

#Preview {
    NavigationStack { DailyView() }
        .modelContainer(for: Habit.self, inMemory: true)
}
