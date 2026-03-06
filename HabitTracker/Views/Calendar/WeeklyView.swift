import SwiftUI
import SwiftData

struct WeeklyView: View {
    @Query(sort: \Habit.createdAt, order: .reverse) private var habits: [Habit]
    @State private var currentWeekStart = Date.now.startOfWeek ?? Date.now
    @State private var habitForDetailsSheet: Habit?
    @State private var editingHabit: Habit?
    
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
                CalendarEmptyState(
                    icon: "square.grid.2x2",
                    title: "No habits yet",
                    message: "Add habits to see your week at a glance."
                )
            } else {
                GeometryReader { geo in
                    let horizontalPadding = LayoutConfig.current.horizontalPadding
                    let contentWidth = geo.size.width - (2 * horizontalPadding)
                    let dayColumnWidth = contentWidth / 7
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Habits this week")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.secondary)
                            .padding(.leading, horizontalPadding)
                        
                        VStack(spacing: 12) {
                            HStack(spacing: 0) {
                                ForEach(weekDates, id: \.self) { date in
                                    Text(date, format: .dateTime.weekday(.narrow))
                                        .font(.caption.weight(.medium))
                                        .foregroundStyle(.secondary)
                                        .frame(width: dayColumnWidth, alignment: .center)
                                }
                            }
                            .padding(.vertical, 12)
                            .frame(width: contentWidth)
                            .background(Color.systemGray6)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            
                            ScrollView {
                                ForEach(habits) { habit in
                                    WeeklyHabitRow(
                                        habit: habit,
                                        dates: weekDates,
                                        dayColumnWidth: dayColumnWidth,
                                        onViewDescription: { habitForDetailsSheet = habit },
                                        onEdit: { editingHabit = habit },
                                        onDelete: { HabitStore.shared.deleteHabit(habit) }
                                    )
                                    .frame(width: contentWidth)
                                }
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal, horizontalPadding)
                    }
                }
                .frame(maxHeight: .infinity)
            }
        }
        .habitSheets(details: $habitForDetailsSheet, editing: $editingHabit)
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
    var dayColumnWidth: CGFloat = 0
    var onViewDescription: (() -> Void)? = nil
    var onEdit: (() -> Void)? = nil
    var onDelete: (() -> Void)? = nil
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                ForEach(dates, id: \.self) { date in
                    DayDot(habit: habit, date: date)
                        .frame(width: dayColumnWidth)
                }
            }
            .padding(.top, 12)
            .padding(.bottom, 10)
            
            Button {
                onViewDescription?()
            } label: {
                HStack(alignment: .center, spacing: 6) {
                    if let emoji = habit.emoji, !emoji.isEmpty {
                        Text(emoji).font(.subheadline)
                    } else if let iconName = habit.iconName {
                        Image(systemName: iconName)
                            .font(.subheadline)
                            .foregroundStyle(habit.color.color)
                    } else {
                        Circle().fill(habit.color.color).frame(width: 18, height: 18)
                    }
                    Text(habit.name)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .padding(.bottom, 12)
        }
        .background(Color.systemGray6)
        .clipShape(RoundedRectangle(cornerRadius: 8))
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
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    NavigationStack { WeeklyView() }.modelContainer(for: Habit.self, inMemory: true)
}
