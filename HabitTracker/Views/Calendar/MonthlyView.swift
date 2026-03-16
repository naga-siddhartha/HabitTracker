import SwiftUI
import SwiftData

struct MonthlyView: View {
    @Query(sort: \Habit.createdAt, order: .reverse) private var allHabits: [Habit]
    @State private var currentMonth = Date.now
    @State private var selectedDate = Date.now
    @State private var habitForDetailsSheet: Habit?
    @State private var editingHabit: Habit?
    @State private var skipReasonTarget: (habit: Habit, date: Date)?
    @State private var skipReasonAlertMessage: String?

    private let config = LayoutConfig.current
    private let calendar = Calendar.current
    private let columns = Array(repeating: GridItem(.flexible()), count: 7)
    private var habits: [Habit] {
        let grouped = Dictionary(grouping: allHabits, by: \.name)
        return grouped.compactMap { _, group in group.first }
            .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    var body: some View {
        let activeHabits = habits.filter { $0.isActive(on: selectedDate) }
        return VStack(spacing: 0) {
            // Fixed calendar block — stays at top
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
                .padding(.bottom, config.spacingL)
            }
            
            // Only the habits section scrolls
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    if activeHabits.isEmpty {
                        CalendarEmptyState(
                            icon: "calendar.badge.clock",
                            title: "No habits scheduled",
                            message: "Tap a day above to see habits for that date."
                        )
                    } else {
                        Text("Habits for this day")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, config.cardContentPaddingHorizontal)
                            .padding(.top, config.spacingL)
                            .padding(.bottom, config.sectionHeaderBottom)
                        
                        VStack(spacing: config.spacingL) {
                            ForEach(activeHabits) { habit in
                                MonthlyHabitRow(
                                    habit: habit,
                                    date: selectedDate,
                                    onViewDescription: { habitForDetailsSheet = habit },
                                    onEdit: { editingHabit = habit },
                                    onDelete: { HabitStore.shared.deleteHabit(habit) },
                                    onUnskip: { HabitStore.shared.unskipDay(for: habit, on: selectedDate) },
                                    onSkipWithReason: { skipReasonTarget = (habit, selectedDate) },
                                    onTapSkipReason: { skipReasonAlertMessage = $0 }
                                )
                            }
                        }
                        .padding(.horizontal, config.spacingL)
                        .padding(.top, config.spacingS)
                        .padding(.bottom, config.spacingL)
                    }
                }
            }
            .frame(maxHeight: .infinity)
        }
        .habitSheets(details: $habitForDetailsSheet, editing: $editingHabit)
        .sheet(item: monthlySkipReasonBinding) { pair in
            SkipReasonSheetView(habit: pair.habit, date: pair.date) { skipReasonTarget = nil }
        }
        .alert("Skip reason", isPresented: Binding(
            get: { skipReasonAlertMessage != nil },
            set: { if !$0 { skipReasonAlertMessage = nil } }
        )) {
            Button("OK") { skipReasonAlertMessage = nil }
        } message: {
            if let msg = skipReasonAlertMessage { Text(msg) }
        }
    }
    
    private var monthlySkipReasonBinding: Binding<SkipReasonSheetItem?> {
        Binding(
            get: { skipReasonTarget.map { SkipReasonSheetItem(habit: $0.habit, date: $0.date) } },
            set: { skipReasonTarget = $0.map { ($0.habit, $0.date) } }
        )
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
        return Double(active.filter { $0.isDone(on: date) }.count) / Double(active.count)
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
    var onUnskip: (() -> Void)? = nil
    var onSkipWithReason: (() -> Void)? = nil
    var onTapSkipReason: ((String) -> Void)? = nil

    private let config = LayoutConfig.current
    private var isCompleted: Bool { habit.isDone(on: date) }
    private var isSkipped: Bool { habit.isSkipped(on: date) }
    private var isRepeating: Bool { habit.reminderIntervalMinutes > 0 }
    private var count: Int { habit.completionCount(on: date) }
    private var expected: Int { habit.expectedCompletions(on: date) }
    private var skipReason: String? { habit.entry(for: date)?.skipReason }
    
    private var skippedSubtitle: String {
        guard isSkipped else { return "" }
        if let reason = skipReason, !reason.isEmpty { return "Skipped · \(reason)" }
        return "Skipped"
    }

    /// Fixed size for the completion button so all cards stay the same height (matches daily).
    private let completionButtonSize: CGFloat = 36

    var body: some View {
        HStack(alignment: .center, spacing: config.spacingL - 2) {
            Button {
                onViewDescription?()
            } label: {
                HStack(alignment: .center, spacing: config.spacingM) {
                    Group {
                        if let emoji = habit.emoji, !emoji.isEmpty {
                            Text(emoji)
                                .font(.title3)
                        } else if let iconName = habit.iconName {
                            Image(systemName: iconName)
                                .font(.title3)
                                .foregroundStyle(habit.displayColor)
                        } else {
                            Circle()
                                .fill(habit.displayColor)
                                .frame(width: config.iconSizeRow, height: config.iconSizeRow)
                        }
                    }
                    .frame(width: completionButtonSize, height: completionButtonSize, alignment: .center)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(habit.name)
                            .font(.body.weight(.medium))
                            .foregroundStyle(isSkipped ? .secondary : .primary)
                            .lineLimit(1)
                            .truncationMode(.tail)
                        if isSkipped {
                            Group {
                                if skipReason != nil, !(skipReason?.isEmpty ?? true) {
                                    Button {
                                        onTapSkipReason?(skippedSubtitle)
                                    } label: {
                                        Text(skippedSubtitle)
                                            .font(.caption)
                                            .foregroundStyle(.orange)
                                            .lineLimit(2)
                                            .truncationMode(.tail)
                                            .multilineTextAlignment(.leading)
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                    }
                                    .buttonStyle(.plain)
                                    .accessibilityHint("Double tap to show full reason")
                                } else {
                                    Text(skippedSubtitle)
                                        .font(.caption)
                                        .foregroundStyle(.orange)
                                        .lineLimit(2)
                                        .truncationMode(.tail)
                                }
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .contentShape(Rectangle())
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            Button {
                withAnimation(.snappy(duration: 0.3)) {
                    if isRepeating {
                        HabitStore.shared.incrementCompletion(for: habit, on: date)
                    } else {
                        HabitStore.shared.toggleCompletion(for: habit, on: date)
                    }
                }
            } label: {
                monthlyCompletionIcon
            }
            .buttonStyle(.plain)
            .frame(width: completionButtonSize, height: completionButtonSize)
            .contentShape(Rectangle())
            .hapticFeedback(.success, trigger: isCompleted)
        }
        .padding(.horizontal, config.spacingL)
        .padding(.vertical, config.cornerRadiusMedium + 2)
        .frame(minHeight: config.progressRingSize - 16)
        .background(isCompleted ? habit.displayColor.opacity(0.14) : habit.displayColor.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: config.cardCornerRadius))
        .cardBorder(cornerRadius: config.cardCornerRadius)
        .contentShape(Rectangle())
        .contextMenu {
            HabitRowActions(
                onViewDetails: { onViewDescription?() },
                onEdit: { onEdit?() },
                onDelete: { onDelete?() },
                showSkipUnskip: true,
                isSkippedOnDate: isSkipped,
                onUnskip: onUnskip,
                onSkipWithReason: onSkipWithReason,
                onMarkAllComplete: isRepeating && !isCompleted ? {
                    withAnimation(.spring(duration: 0.25)) {
                        HabitStore.shared.markAllComplete(for: habit, on: date)
                    }
                } : nil,
                onResetCompletion: isRepeating && count > 0 ? {
                    withAnimation(.spring(duration: 0.25)) {
                        HabitStore.shared.resetCompletion(for: habit, on: date)
                    }
                } : nil
            )
        }
    }

    @ViewBuilder
    private var monthlyCompletionIcon: some View {
        if isSkipped {
            Image(systemName: "pause.circle.fill")
                .font(.system(size: 22, weight: .medium))
                .foregroundStyle(.orange)
                .frame(width: completionButtonSize, height: completionButtonSize)
        } else if isRepeating {
            VStack(spacing: 2) {
                ZStack {
                    Circle()
                        .stroke(count > 0 ? habit.displayColor : Color.secondary.opacity(0.3), lineWidth: 2)
                        .frame(width: 28, height: 28)
                    if isCompleted {
                        Circle().fill(habit.displayColor).frame(width: 28, height: 28)
                        Image(systemName: "checkmark")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(.white)
                    } else if let emoji = habit.emoji, !emoji.isEmpty {
                        Text(emoji).font(.system(size: 13)).opacity(count > 0 ? 1 : 0.35)
                    } else {
                        Image(systemName: count > 0 ? "checkmark" : "circle")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(count > 0 ? habit.displayColor : .secondary)
                    }
                }
                .frame(width: completionButtonSize, height: 28)
                Text("\(count)/\(expected)")
                    .font(.system(size: 9, weight: .semibold, design: .rounded))
                    .foregroundStyle(count > 0 ? habit.displayColor : .secondary)
                    .monospacedDigit()
            }
            .frame(height: completionButtonSize)
            .animation(.spring(duration: 0.2), value: count)
        } else {
            ZStack {
                Circle()
                    .stroke(isCompleted ? habit.displayColor : Color.secondary.opacity(0.25), lineWidth: 2)
                    .frame(width: 28, height: 28)
                if isCompleted {
                    Circle().fill(habit.displayColor).frame(width: 28, height: 28)
                    Image(systemName: "checkmark")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(.white)
                } else {
                    Image(systemName: "circle")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.secondary)
                }
            }
            .frame(width: completionButtonSize, height: completionButtonSize)
            .contentTransition(.symbolEffect(.replace))
            .animation(.spring(duration: 0.25), value: isCompleted)
        }
    }
}

#Preview {
    NavigationStack { MonthlyView() }.modelContainer(for: Habit.self, inMemory: true)
}
