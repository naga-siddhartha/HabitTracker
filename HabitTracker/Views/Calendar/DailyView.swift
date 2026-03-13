import SwiftUI
import SwiftData

struct DailyView: View {
    @Query(sort: \Habit.createdAt, order: .reverse) private var allHabits: [Habit]
    @State private var selectedDate = Date.now
    @State private var habitForDetailsSheet: Habit?
    @State private var editingHabit: Habit?
    @State private var skipReasonTarget: (habit: Habit, date: Date)?
    @State private var skipReasonAlertMessage: String?
    private let config = LayoutConfig.current

    private var habits: [Habit] {
        let grouped = Dictionary(grouping: allHabits, by: \.name)
        return grouped.compactMap { _, group in group.first }
            .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }
    private var activeHabits: [Habit] { habits.filter { $0.isActive(on: selectedDate) } }

    var body: some View {
        VStack(spacing: 0) {
            DatePicker("Date", selection: $selectedDate, displayedComponents: .date)
                #if os(macOS)
                .datePickerStyle(.field)
                #else
                .datePickerStyle(.compact)
                #endif
                .padding()

            if activeHabits.isEmpty {
                CalendarEmptyState(
                    icon: "calendar.badge.clock",
                    title: "No habits scheduled",
                    message: "Pick another date or add habits that are active on this day."
                )
            } else {
                VStack(alignment: .leading, spacing: 0) {
                    Text("Habits for this day")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, config.cardContentPaddingHorizontal)
                        .padding(.top, config.spacingL)
                        .padding(.bottom, config.spacingS)
                    List(activeHabits) { habit in
                        DailyHabitRow(
                            habit: habit,
                            date: selectedDate,
                            onViewDescription: { habitForDetailsSheet = habit },
                            onEdit: { editingHabit = habit },
                            onDelete: { HabitStore.shared.deleteHabit(habit) },
                            onUnskip: { HabitStore.shared.unskipDay(for: habit, on: selectedDate) },
                            onSkipWithReason: { skipReasonTarget = (habit, selectedDate) },
                            onTapSkipReason: { skipReasonAlertMessage = $0 }
                        )
                        .listRowInsets(EdgeInsets(top: config.spacingL / 2, leading: config.cardContentPaddingHorizontal, bottom: config.spacingL / 2, trailing: config.cardContentPaddingHorizontal))
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                    .padding(.bottom, config.spacingL)
                }
            }
        }
        .habitSheets(details: $habitForDetailsSheet, editing: $editingHabit)
        .sheet(item: skipReasonBinding) { pair in
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
    
    private var skipReasonBinding: Binding<SkipReasonSheetItem?> {
        Binding(
            get: { skipReasonTarget.map { SkipReasonSheetItem(habit: $0.habit, date: $0.date) } },
            set: { skipReasonTarget = $0.map { ($0.habit, $0.date) } }
        )
    }
}

struct DailyHabitRow: View {
    @Bindable var habit: Habit
    let date: Date
    var onViewDescription: (() -> Void)? = nil
    var onEdit: (() -> Void)? = nil
    var onDelete: (() -> Void)? = nil
    var onUnskip: (() -> Void)? = nil
    var onSkipWithReason: (() -> Void)? = nil
    var onTapSkipReason: ((String) -> Void)? = nil

    private var isCompleted: Bool { habit.isDone(on: date) }
    private var isSkipped: Bool { habit.isSkipped(on: date) }
    private var isRepeating: Bool { habit.reminderIntervalMinutes > 0 }
    private var count: Int { habit.completionCount(on: date) }
    private var expected: Int { habit.expectedCompletions(on: date) }
    private var skipReason: String? { habit.entry(for: date)?.skipReason }

    private var subtitleText: String {
        if isSkipped {
            if let reason = skipReason, !reason.isEmpty { return "Skipped · \(reason)" }
            return "Skipped"
        }
        if isRepeating {
            if let schedule = habit.scheduleDescription { return schedule }
        }
        return habit.reminderTimes.isEmpty ? "All day" : (habit.reminderTimes.first!.formatted(date: .omitted, time: .shortened))
    }

    var body: some View {
        HStack(alignment: .center, spacing: LayoutConfig.current.spacingL - 2) {
            Button { onViewDescription?() } label: {
                HStack(alignment: .center, spacing: LayoutConfig.current.spacingL - 2) {
                    if let emoji = habit.emoji, !emoji.isEmpty {
                        Text(emoji).font(.title2).opacity(isCompleted ? 0.5 : 1.0)
                    } else if let iconName = habit.iconName {
                        Image(systemName: iconName).foregroundStyle(habit.displayColor).font(.title2)
                    } else {
                        Circle().fill(habit.displayColor).frame(width: LayoutConfig.current.iconSizeRow, height: LayoutConfig.current.iconSizeRow)
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text(habit.name)
                            .strikethrough(isCompleted)
                            .font(.body.weight(.medium))
                            .foregroundStyle(isSkipped ? .secondary : .primary)
                        Group {
                            if isSkipped, let reason = skipReason, !reason.isEmpty {
                                Button { onTapSkipReason?(subtitleText) } label: {
                                    Text(subtitleText)
                                        .font(.caption).foregroundStyle(.orange)
                                        .lineLimit(2).truncationMode(.tail)
                                        .multilineTextAlignment(.leading)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                }
                                .buttonStyle(.plain)
                                .accessibilityHint("Double tap to show full reason")
                            } else {
                                Text(subtitleText)
                                    .font(.caption)
                                    .foregroundStyle(isSkipped ? .orange : .secondary)
                                    .lineLimit(isSkipped ? 2 : 1)
                                    .truncationMode(.tail)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .contentShape(Rectangle())
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            // Completion button: emoji ring for single, count badge for repeating
            Button {
                withAnimation(.spring(duration: 0.25, bounce: 0.3)) {
                    if isRepeating {
                        HabitStore.shared.incrementCompletion(for: habit, on: date)
                    } else {
                        HabitStore.shared.toggleCompletion(for: habit, on: date)
                    }
                }
            } label: {
                dailyCompletionButton
            }
            .buttonStyle(.plain)
            .frame(minWidth: LayoutConfig.current.iconSizeButton, minHeight: LayoutConfig.current.iconSizeButton)
            .contentShape(Rectangle())
            .hapticFeedback(.success, trigger: isCompleted)
        }
        .padding(.horizontal, LayoutConfig.current.spacingL)
        .padding(.vertical, LayoutConfig.current.cornerRadiusMedium + 2)
        .frame(minHeight: LayoutConfig.current.progressRingSize - 16)
        .background(backgroundColor)
        .clipShape(RoundedRectangle(cornerRadius: LayoutConfig.current.cardCornerRadius))
        .cardBorder(cornerRadius: LayoutConfig.current.cardCornerRadius)
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
    private var dailyCompletionButton: some View {
        if isSkipped {
            Image(systemName: "pause.circle.fill")
                .font(.title2)
                .foregroundStyle(.orange)
        } else if isRepeating {
            // Emoji with count ring for repeating habits
            VStack(spacing: 3) {
                ZStack {
                    Circle()
                        .stroke(count > 0 ? habit.displayColor : Color.secondary.opacity(0.25), lineWidth: 2)
                        .frame(width: 32, height: 32)
                    if let emoji = habit.emoji, !emoji.isEmpty {
                        Text(emoji)
                            .font(.system(size: 16))
                            .opacity(count > 0 ? 1.0 : 0.3)
                    } else {
                        Image(systemName: count > 0 ? "checkmark" : "circle")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(count > 0 ? habit.displayColor : .secondary)
                    }
                }
                Text("\(count)/\(expected)")
                    .font(.system(size: 10, weight: .semibold, design: .rounded))
                    .foregroundStyle(count > 0 ? habit.displayColor : .secondary)
                    .monospacedDigit()
            }
            .animation(.spring(duration: 0.25), value: count)
        } else {
            // Single-completion: emoji or checkmark
            ZStack {
                Circle()
                    .stroke(isCompleted ? habit.displayColor : Color.secondary.opacity(0.25), lineWidth: 2)
                    .frame(width: 32, height: 32)
                if let emoji = habit.emoji, !emoji.isEmpty {
                    Text(emoji)
                        .font(.system(size: 16))
                        .opacity(isCompleted ? 1.0 : 0.3)
                } else {
                    if isCompleted {
                        Circle().fill(habit.displayColor).frame(width: 32, height: 32)
                        Image(systemName: "checkmark").font(.system(size: 12, weight: .bold)).foregroundStyle(.white)
                    }
                }
            }
            .contentTransition(.symbolEffect(.replace))
            .animation(.spring(duration: 0.25), value: isCompleted)
        }
    }

    private var backgroundColor: Color {
        if isSkipped { return Color.orange.opacity(0.08) }
        return isCompleted ? habit.displayColor.opacity(0.14) : habit.displayColor.opacity(0.08)
    }
}

#Preview {
    NavigationStack { DailyView() }.modelContainer(for: Habit.self, inMemory: true)
}
