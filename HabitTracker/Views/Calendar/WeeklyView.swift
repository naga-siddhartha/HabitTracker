import SwiftUI
import SwiftData

struct WeeklyView: View {
    @Query(sort: \Habit.createdAt, order: .reverse) private var habits: [Habit]
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
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
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
                        Text(date, format: .dateTime.weekday(.narrow))
                            .font(.caption.weight(.medium))
                            .foregroundStyle(.secondary)
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
        HStack(alignment: .top) {
            HStack(alignment: .top, spacing: 6) {
                if let emoji = habit.emoji, !emoji.isEmpty {
                    Text(emoji).font(.caption)
                } else if let iconName = habit.iconName {
                    Image(systemName: iconName).foregroundStyle(habit.color.color)
                } else {
                    Circle().fill(habit.color.color).frame(width: 20, height: 20)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(habit.name).font(.caption).lineLimit(1)
                    if let desc = habit.habitDescription, !desc.isEmpty {
                        Text(desc).font(.caption2).foregroundStyle(.secondary).lineLimit(1)
                    }
                }
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
    private var isActive: Bool { habit.isActive(on: date) }
    
    var body: some View {
        Button {
            if isActive {
                withAnimation(.snappy(duration: 0.3)) {
                    HabitStore.shared.toggleCompletion(for: habit, on: date)
                }
            }
        } label: {
            ZStack {
                if isCompleted {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 26))
                        .foregroundStyle(habit.color.color)
                } else if isSkipped {
                    Image(systemName: "minus.circle.fill")
                        .font(.system(size: 26))
                        .foregroundStyle(.orange)
                } else {
                    Image(systemName: "circle")
                        .font(.system(size: 26))
                        .foregroundStyle(isActive ? Color.systemGray4 : Color.systemGray5.opacity(0.6))
                }
            }
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
