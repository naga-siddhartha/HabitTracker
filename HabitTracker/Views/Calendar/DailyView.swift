import SwiftUI
import SwiftData

struct DailyView: View {
    @Query(sort: \Habit.createdAt, order: .reverse) private var habits: [Habit]
    @State private var selectedDate = Date.now
    @State private var habitForDetailsSheet: Habit?
    @State private var editingHabit: Habit?
    @State private var skipReasonTarget: (habit: Habit, date: Date)?
    
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
                        .padding(.horizontal, 20)
                        .padding(.top, 12)
                        .padding(.bottom, 8)
                    List(activeHabits) { habit in
                        DailyHabitRow(
                            habit: habit,
                            date: selectedDate,
                            onViewDescription: { habitForDetailsSheet = habit },
                            onEdit: { editingHabit = habit },
                            onDelete: { HabitStore.shared.deleteHabit(habit) },
                            onUnskip: { HabitStore.shared.unskipDay(for: habit, on: selectedDate) },
                            onSkipWithReason: { skipReasonTarget = (habit, selectedDate) }
                        )
                        .listRowInsets(EdgeInsets(top: 6, leading: 20, bottom: 6, trailing: 20))
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                }
            }
        }
        .habitSheets(details: $habitForDetailsSheet, editing: $editingHabit)
        .sheet(item: skipReasonBinding) { pair in
            SkipReasonSheetView(habit: pair.habit, date: pair.date) { skipReasonTarget = nil }
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
    
    private var isCompleted: Bool { habit.isCompleted(on: date) }
    private var isSkipped: Bool { habit.isSkipped(on: date) }
    private var skipReason: String? { habit.entry(for: date)?.skipReason }
    
    private var checkmarkIcon: some View {
        Group {
            if isSkipped {
                Image(systemName: "pause.circle.fill")
                    .font(.title2)
                    .foregroundStyle(.orange)
            } else {
                Image(systemName: isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundStyle(isCompleted ? habit.color.color : .secondary)
            }
        }
        .contentTransition(.symbolEffect(.replace))
    }

    private var subtitleText: String {
        if isSkipped {
            if let reason = skipReason, !reason.isEmpty { return "Skipped · \(reason)" }
            return "Skipped"
        }
        return habit.reminderTimes.isEmpty ? "All day" : (habit.reminderTimes.first!.formatted(date: .omitted, time: .shortened))
    }

    var body: some View {
        HStack(alignment: .center, spacing: 14) {
            Button {
                onViewDescription?()
            } label: {
                HStack(alignment: .center, spacing: 14) {
                    if let emoji = habit.emoji, !emoji.isEmpty {
                        Text(emoji).font(.title2)
                    } else if let iconName = habit.iconName {
                        Image(systemName: iconName).foregroundStyle(habit.color.color).font(.title2)
                    } else {
                        Circle().fill(habit.color.color).frame(width: 28, height: 28)
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text(habit.name)
                            .strikethrough(isCompleted)
                            .font(.body.weight(.medium))
                            .foregroundStyle(isSkipped ? .secondary : .primary)
                        Text(subtitleText)
                            .font(.caption)
                            .foregroundStyle(isSkipped ? .orange : .secondary)
                            .lineLimit(1)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .contentShape(Rectangle())
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            Button {
                withAnimation(.snappy(duration: 0.3)) {
                    HabitStore.shared.toggleCompletion(for: habit, on: date)
                }
            } label: { checkmarkIcon }
            .buttonStyle(.plain)
            .frame(minWidth: 44, minHeight: 44)
            .contentShape(Rectangle())
            .hapticFeedback(.success, trigger: isCompleted)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .frame(minHeight: 56)
        .background(backgroundColor)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .contentShape(Rectangle())
        .contextMenu {
            HabitRowActions(
                onViewDetails: { onViewDescription?() },
                onEdit: { onEdit?() },
                onDelete: { onDelete?() },
                showSkipUnskip: true,
                isSkippedOnDate: isSkipped,
                onUnskip: onUnskip,
                onSkipWithReason: onSkipWithReason
            )
        }
    }
    
    private var backgroundColor: Color {
        if isSkipped { return Color.orange.opacity(0.08) }
        return isCompleted ? habit.color.color.opacity(0.1) : Color.systemGray6
    }
}

#Preview {
    NavigationStack { DailyView() }.modelContainer(for: Habit.self, inMemory: true)
}
