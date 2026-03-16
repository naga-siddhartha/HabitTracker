import SwiftUI
import SwiftData

struct WeeklyView: View {
    @Query(sort: \Habit.createdAt, order: .reverse) private var allHabits: [Habit]
    @State private var currentWeekStart = Date.now.startOfWeek ?? Date.now
    @State private var habitForDetailsSheet: Habit?
    @State private var editingHabit: Habit?
    @State private var skipReasonTarget: (habit: Habit, date: Date)?

    private let calendar = Calendar.current
    private var weekDates: [Date] {
        (0..<7).compactMap { calendar.date(byAdding: .day, value: $0, to: currentWeekStart) }
    }
    /// One representative habit per unique name, matching HomeView deduplication.
    private var habits: [Habit] {
        let grouped = Dictionary(grouping: allHabits, by: \.name)
        return grouped.compactMap { _, group in group.first }
            .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
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
                    
                    VStack(alignment: .leading, spacing: LayoutConfig.current.spacingL) {
                        Text("Habits this week")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.secondary)
                            .padding(.leading, horizontalPadding)
                        
                        VStack(spacing: LayoutConfig.current.spacingL) {
                            HStack(spacing: 0) {
                                ForEach(weekDates, id: \.self) { date in
                                    Text(date, format: .dateTime.weekday(.narrow))
                                        .font(.caption.weight(.medium))
                                        .foregroundStyle(.secondary)
                                        .frame(width: dayColumnWidth, alignment: .center)
                                }
                            }
                            .padding(.vertical, LayoutConfig.current.spacingM)
                            .frame(width: contentWidth)
                            .background(Color.systemGray6)
                            .clipShape(RoundedRectangle(cornerRadius: LayoutConfig.current.cornerRadiusSmall))
                            .cardBorder(cornerRadius: LayoutConfig.current.cornerRadiusSmall)
                            
                            ScrollView {
                                VStack(alignment: .leading, spacing: LayoutConfig.current.spacingL) {
                                    ForEach(habits) { habit in
                                        WeeklyHabitRow(
                                            habit: habit,
                                            dates: weekDates,
                                            dayColumnWidth: dayColumnWidth,
                                            onViewDescription: { habitForDetailsSheet = habit },
                                            onEdit: { editingHabit = habit },
                                            onDelete: { HabitStore.shared.deleteHabit(habit) },
                                            onSkipWithReason: { date in skipReasonTarget = (habit, date) }
                                        )
                                        .frame(width: contentWidth)
                                    }
                                }
                                .padding(.bottom, LayoutConfig.current.spacingL)
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
        .sheet(item: weeklySkipReasonBinding) { pair in
            SkipReasonSheetView(habit: pair.habit, date: pair.date) { skipReasonTarget = nil }
        }
    }
    
    private var weeklySkipReasonBinding: Binding<SkipReasonSheetItem?> {
        Binding(
            get: { skipReasonTarget.map { SkipReasonSheetItem(habit: $0.habit, date: $0.date) } },
            set: { skipReasonTarget = $0.map { ($0.habit, $0.date) } }
        )
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
    var onSkipWithReason: ((Date) -> Void)? = nil
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                ForEach(dates, id: \.self) { date in
                    DayDot(
                        habit: habit,
                        date: date,
                        onUnskip: { HabitStore.shared.unskipDay(for: habit, on: date) },
                        onSkipWithReason: { onSkipWithReason?(date) }
                    )
                    .frame(width: dayColumnWidth)
                }
            }
            .padding(.top, LayoutConfig.current.spacingM)
            .padding(.bottom, LayoutConfig.current.cardRowPaddingVertical)
            
            Button {
                onViewDescription?()
            } label: {
                HStack(alignment: .center, spacing: 6) {
                    if let emoji = habit.emoji, !emoji.isEmpty {
                        Text(emoji).font(.subheadline)
                    } else if let iconName = habit.iconName {
                        Image(systemName: iconName)
                            .font(.subheadline)
                            .foregroundStyle(habit.displayColor)
                    } else {
                        Circle().fill(habit.displayColor).frame(width: LayoutConfig.current.spacingM + 6, height: LayoutConfig.current.spacingM + 6)
                    }
                    Text(habit.name)
                        .font(.body.weight(.medium))
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .padding(.bottom, 12)
        }
        .background(habit.displayColor.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: LayoutConfig.current.cardCornerRadius))
        .cardBorder(cornerRadius: LayoutConfig.current.cardCornerRadius)
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
    var onUnskip: (() -> Void)? = nil
    var onSkipWithReason: (() -> Void)? = nil
    
    private var isCompleted: Bool { habit.isDone(on: date) }
    private var isSkipped: Bool { habit.isSkipped(on: date) }
    private var isActive: Bool { habit.isActive(on: date) }
    private var isRepeating: Bool { habit.reminderIntervalMinutes > 0 }
    private var count: Int { habit.completionCount(on: date) }
    private var expected: Int { habit.expectedCompletions(on: date) }

    var body: some View {
        Button {
            if isActive {
                withAnimation(.snappy(duration: 0.3)) {
                    if isRepeating {
                        HabitStore.shared.incrementCompletion(for: habit, on: date)
                    } else {
                        HabitStore.shared.toggleCompletion(for: habit, on: date)
                    }
                }
            }
        } label: {
            ZStack {
                if isCompleted {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 26))
                        .foregroundStyle(habit.displayColor)
                } else if isRepeating && count > 0 {
                    ZStack {
                        Circle()
                            .stroke(habit.displayColor.opacity(0.3), lineWidth: 2.5)
                            .frame(width: 26, height: 26)
                        Circle()
                            .trim(from: 0, to: CGFloat(count) / CGFloat(expected))
                            .stroke(habit.displayColor, style: StrokeStyle(lineWidth: 2.5, lineCap: .round))
                            .rotationEffect(.degrees(-90))
                            .frame(width: 26, height: 26)
                        Text("\(count)")
                            .font(.system(size: 9, weight: .bold, design: .rounded))
                            .foregroundStyle(habit.displayColor)
                    }
                } else if isSkipped {
                    Image(systemName: "pause.circle.fill")
                        .font(.system(size: 26))
                        .foregroundStyle(.orange)
                } else {
                    Image(systemName: "circle")
                        .font(.system(size: 26))
                        .foregroundStyle(isActive ? Color.systemGray4 : Color.systemGray5.opacity(0.6))
                }
            }
            .frame(minWidth: 44, minHeight: 44)
            .contentShape(Rectangle())
            .animation(.spring(duration: 0.2), value: isCompleted)
            .animation(.spring(duration: 0.2), value: isSkipped)
        }
        .buttonStyle(.plain)
        .hapticFeedback(.success, trigger: isCompleted)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .contextMenu {
            if isActive {
                HabitRowActions(
                    showSkipUnskip: true,
                    isSkippedOnDate: isSkipped,
                    onUnskip: onUnskip,
                    onSkipWithReason: onSkipWithReason,
                    onMarkAllComplete: isRepeating && !isCompleted ? {
                        withAnimation(.snappy(duration: 0.3)) {
                            HabitStore.shared.markAllComplete(for: habit, on: date)
                        }
                    } : nil,
                    onResetCompletion: isRepeating && count > 0 ? {
                        withAnimation(.snappy(duration: 0.3)) {
                            HabitStore.shared.resetCompletion(for: habit, on: date)
                        }
                    } : nil
                )
            }
        }
    }
}

#Preview {
    NavigationStack { WeeklyView() }.modelContainer(for: Habit.self, inMemory: true)
}
