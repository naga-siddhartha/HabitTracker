import SwiftUI
import SwiftData

struct DailyView: View {
    @Query(sort: \Habit.createdAt, order: .reverse) private var habits: [Habit]
    @State private var selectedDate = Date.now
    @State private var habitForDetailsSheet: Habit?
    @State private var editingHabit: Habit?
    
    private var activeHabits: [Habit] { habits.filter { $0.isActive(on: selectedDate) } }
    
    var body: some View {
        VStack(spacing: 0) {
            DatePicker("Date", selection: $selectedDate, displayedComponents: .date)
                .datePickerStyle(.compact)
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
                            onDelete: { HabitStore.shared.deleteHabit(habit) }
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
    }
}

struct DailyHabitRow: View {
    @Bindable var habit: Habit
    let date: Date
    var onViewDescription: (() -> Void)? = nil
    var onEdit: (() -> Void)? = nil
    var onDelete: (() -> Void)? = nil
    
    private var isCompleted: Bool { habit.isCompleted(on: date) }
    
    private var checkmarkIcon: some View {
        Image(systemName: isCompleted ? "checkmark.circle.fill" : "circle")
            .font(.title2)
            .foregroundStyle(isCompleted ? habit.color.color : .secondary)
            .contentTransition(.symbolEffect(.replace))
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
                    Text(habit.name)
                        .strikethrough(isCompleted)
                        .font(.body.weight(.medium))
                        .foregroundStyle(.primary)
                    Spacer(minLength: 0)
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
            .hapticFeedback(.success, trigger: isCompleted)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .frame(minHeight: 56)
        .background(isCompleted ? habit.color.color.opacity(0.1) : Color.systemGray6)
        .clipShape(RoundedRectangle(cornerRadius: 10))
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
    NavigationStack { DailyView() }.modelContainer(for: Habit.self, inMemory: true)
}
