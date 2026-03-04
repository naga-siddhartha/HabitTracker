import SwiftUI
import SwiftData

struct WeeklyView: View {
    @Query(filter: #Predicate<Habit> { !$0.isArchived }) private var habits: [Habit]
    @State private var currentWeekStart = Date.now.startOfWeek ?? Date.now
    
    private let calendar = Calendar.current
    private var weekDates: [Date] {
        (0..<7).compactMap { calendar.date(byAdding: .day, value: $0, to: currentWeekStart) }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Button { changeWeek(by: -1) } label: { Image(systemName: "chevron.left") }
                Spacer()
                Text(weekRangeText).font(.headline)
                Spacer()
                Button { changeWeek(by: 1) } label: { Image(systemName: "chevron.right") }
            }
            .padding()
            
            if habits.isEmpty {
                VStack(spacing: 10) {
                    Image(systemName: "square.grid.2x2")
                        .font(.system(size: 36))
                        .foregroundStyle(.secondary.opacity(0.7))
                    Text("No habits yet")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                    Text("Add habits to see your week at a glance.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary.opacity(0.8))
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 28)
                .padding(.horizontal, 20)
            } else {
                Text("Habits this week")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 8)
                
                HStack {
                    Text("Habit").frame(width: 100, alignment: .leading)
                    ForEach(weekDates, id: \.self) { date in
                        VStack {
                            Text(date, format: .dateTime.weekday(.narrow))
                            Text(date, format: .dateTime.day())
                        }
                        .font(.caption)
                        .frame(maxWidth: .infinity)
                    }
                }
                .padding(.horizontal)
                
                ScrollView {
                    ForEach(habits) { habit in
                        WeeklyHabitRow(habit: habit, dates: weekDates)
                    }
                }
            }
        }
        .navigationTitle("Weekly")
    }
    
    private var weekRangeText: String {
        guard let end = weekDates.last else { return "" }
        return "\(currentWeekStart.formatted(.dateTime.month().day())) - \(end.formatted(.dateTime.month().day()))"
    }
    
    private func changeWeek(by value: Int) {
        if let newWeek = calendar.date(byAdding: .weekOfYear, value: value, to: currentWeekStart) {
            currentWeekStart = newWeek.startOfWeek ?? newWeek
        }
    }
}

struct WeeklyHabitRow: View {
    @Bindable var habit: Habit
    let dates: [Date]
    
    var body: some View {
        HStack {
            HStack {
                if let iconName = habit.iconName {
                    Image(systemName: iconName).foregroundStyle(habit.color.color)
                } else {
                    Circle().fill(habit.color.color).frame(width: 20, height: 20)
                }
                Text(habit.name).font(.caption).lineLimit(1)
            }
            .frame(width: 100, alignment: .leading)
            
            ForEach(dates, id: \.self) { date in
                DayDot(habit: habit, date: date)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color.systemGray6)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .padding(.horizontal)
    }
}

private struct DayDot: View {
    @Bindable var habit: Habit
    let date: Date
    
    private var isCompleted: Bool { habit.isCompleted(on: date) }
    private var isSkipped: Bool { habit.isSkipped(on: date) }
    
    var body: some View {
        Button {
            if habit.isActive(on: date) {
                withAnimation(.snappy(duration: 0.3)) {
                    HabitStore.shared.toggleCompletion(for: habit, on: date)
                }
            }
        } label: {
            Circle()
                .fill(isCompleted ? habit.color.color : (isSkipped ? .orange : Color.systemGray4))
                .frame(width: 24, height: 24)
                .opacity(habit.isActive(on: date) ? 1 : 0.3)
                .overlay {
                    if isSkipped {
                        Image(systemName: "forward.fill").font(.system(size: 8)).foregroundStyle(.white)
                    }
                }
                .scaleEffect(isCompleted ? 1.15 : 1.0)
                .animation(.spring(duration: 0.2), value: isCompleted)
        }
        .buttonStyle(.plain)
        .hapticFeedback(.success, trigger: isCompleted)
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    NavigationStack { WeeklyView() }.modelContainer(for: Habit.self, inMemory: true)
}
