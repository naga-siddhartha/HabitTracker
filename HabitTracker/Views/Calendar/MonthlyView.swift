import SwiftUI
import SwiftData

struct MonthlyView: View {
    @Query(sort: \Habit.createdAt, order: .reverse) private var habits: [Habit]
    @State private var currentMonth = Date.now
    @State private var selectedDate = Date.now
    @State private var habitForDetailsSheet: Habit?
    @State private var editingHabit: Habit?
    
    private let calendar = Calendar.current
    private let columns = Array(repeating: GridItem(.flexible()), count: 7)
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Button { changeMonth(by: -1) } label: { Image(systemName: "chevron.left") }
                Spacer()
                Text(currentMonth, format: .dateTime.month(.wide).year()).font(.headline)
                Spacer()
                Button { changeMonth(by: 1) } label: { Image(systemName: "chevron.right") }
            }
            .padding()
            
            LazyVGrid(columns: columns, spacing: 4) {
                ForEach(Array(["S", "M", "T", "W", "T", "F", "S"].enumerated()), id: \.offset) { _, day in
                    Text(day).font(.caption).foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal)
            
            LazyVGrid(columns: columns, spacing: 4) {
                ForEach(daysInMonth, id: \.self) { date in
                    MonthDayCell(date: date, habits: habits, currentMonth: currentMonth, isSelected: calendar.isDate(date, inSameDayAs: selectedDate))
                        .onTapGesture { selectedDate = date }
                }
            }
            .padding(.horizontal)
            
            let activeHabits = habits.filter { $0.isActive(on: selectedDate) }
            
            Divider().padding(.vertical, 16)
            
            if activeHabits.isEmpty {
                CalendarEmptyState(
                    icon: "calendar.badge.clock",
                    title: "No habits scheduled",
                    message: "Tap a day above to see habits for that date."
                )
            } else {
                VStack(alignment: .leading, spacing: 0) {
                    Text("Habits for this day")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 20)
                        .padding(.top, 16)
                        .padding(.bottom, 12)
                    
                    VStack(spacing: 0) {
                        ForEach(activeHabits) { habit in
                            MonthlyHabitRow(
                                habit: habit,
                                date: selectedDate,
                                onViewDescription: { habitForDetailsSheet = habit },
                                onEdit: { editingHabit = habit },
                                onDelete: { HabitStore.shared.deleteHabit(habit) }
                            )
                        }
                    }
                    .background(Color.systemBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .padding(.horizontal, 16)
                }
            }
            
            Spacer()
        }
        .habitSheets(details: $habitForDetailsSheet, editing: $editingHabit)
    }
    
    private var daysInMonth: [Date] {
        guard let monthStart = currentMonth.startOfMonth,
              let daysInMonth = calendar.range(of: .day, in: .month, for: currentMonth)?.count else { return [] }
        
        let firstWeekday = calendar.component(.weekday, from: monthStart)
        var dates: [Date] = (0..<(firstWeekday - 1)).compactMap {
            calendar.date(byAdding: .day, value: -($0 + 1), to: monthStart)
        }.reversed()
        
        dates += (0..<daysInMonth).compactMap { calendar.date(byAdding: .day, value: $0, to: monthStart) }
        
        let remaining = 42 - dates.count
        if let last = dates.last {
            dates += (1...remaining).compactMap { calendar.date(byAdding: .day, value: $0, to: last) }
        }
        return dates
    }
    
    private func changeMonth(by value: Int) {
        if let newMonth = calendar.date(byAdding: .month, value: value, to: currentMonth) {
            currentMonth = newMonth
        }
    }
}

struct MonthDayCell: View {
    let date: Date
    let habits: [Habit]
    let currentMonth: Date
    let isSelected: Bool
    
    private let calendar = Calendar.current
    private var isCurrentMonth: Bool { calendar.isDate(date, equalTo: currentMonth, toGranularity: .month) }
    
    private var completionRatio: Double {
        let active = habits.filter { $0.isActive(on: date) }
        guard !active.isEmpty else { return 0 }
        return Double(active.filter { $0.isCompleted(on: date) }.count) / Double(active.count)
    }
    
    var body: some View {
        ZStack {
            Circle().fill(Color.green.opacity(completionRatio * 0.8)).opacity(isCurrentMonth ? 1 : 0.3)
            Text("\(calendar.component(.day, from: date))")
                .font(.caption)
                .foregroundStyle(isCurrentMonth ? .primary : .secondary)
        }
        .frame(height: 36)
        .background(isSelected ? Color.blue.opacity(0.3) : .clear)
        .clipShape(Circle())
    }
}

struct MonthlyHabitRow: View {
    @Bindable var habit: Habit
    let date: Date
    var onViewDescription: (() -> Void)? = nil
    var onEdit: (() -> Void)? = nil
    var onDelete: (() -> Void)? = nil
    
    private var isCompleted: Bool { habit.isCompleted(on: date) }
    
    var body: some View {
        Button {
            withAnimation(.snappy(duration: 0.3)) {
                HabitStore.shared.toggleCompletion(for: habit, on: date)
            }
        } label: {
            HStack(alignment: .top) {
                if let emoji = habit.emoji, !emoji.isEmpty {
                    Text(emoji).font(.subheadline)
                } else {
                    Circle().fill(habit.color.color).frame(width: 12, height: 12)
                }
                Text(habit.name)
                Spacer()
                Image(systemName: isCompleted ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(isCompleted ? habit.color.color : .secondary)
                    .contentTransition(.symbolEffect(.replace))
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
        .buttonStyle(.plain)
        .hapticFeedback(.success, trigger: isCompleted)
        .contentShape(Rectangle())
        .contextMenu {
            HabitRowActions(
                onViewDetails: { onViewDescription?() },
                onEdit: { onEdit?() },
                onDelete: { onDelete?() }
            )
        }
    }
}

#Preview {
    NavigationStack { MonthlyView() }.modelContainer(for: Habit.self, inMemory: true)
}
