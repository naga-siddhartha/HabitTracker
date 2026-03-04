import SwiftUI
import SwiftData

struct DailyView: View {
    @Query(sort: \Habit.createdAt, order: .reverse) private var habits: [Habit]
    @State private var selectedDate = Date.now
    @State private var showingDescriptionSheet = false
    @State private var descriptionSheetTitle = ""
    @State private var descriptionSheetText = ""
    @State private var editingHabit: Habit?
    
    private var activeHabits: [Habit] { habits.filter { $0.isActive(on: selectedDate) } }
    
    var body: some View {
        VStack(spacing: 0) {
            DatePicker("Date", selection: $selectedDate, displayedComponents: .date)
                .datePickerStyle(.compact)
                .padding()
            
            if activeHabits.isEmpty {
                VStack(spacing: 10) {
                    Image(systemName: "calendar.badge.clock")
                        .font(.system(size: 36))
                        .foregroundStyle(.secondary.opacity(0.7))
                    Text("No habits scheduled")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                    Text("Pick another date or add habits that are active on this day.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary.opacity(0.8))
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                .padding(.vertical, 28)
                .padding(.horizontal, 20)
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
                            onViewDescription: habit.habitDescription.flatMap { d in d.isEmpty ? nil : { descriptionSheetTitle = habit.name; descriptionSheetText = d; showingDescriptionSheet = true } },
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
        .sheet(isPresented: $showingDescriptionSheet) {
            HabitDescriptionSheetView(title: descriptionSheetTitle, text: descriptionSheetText) {
                showingDescriptionSheet = false
            }
        }
        .sheet(item: $editingHabit) { habit in
            AddEditHabitView(habit: habit)
        }
    }
}

struct DailyHabitRow: View {
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
                    Text(emoji).font(.title2)
                } else if let iconName = habit.iconName {
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
        .hapticFeedback(.success, trigger: isCompleted)
        .contentShape(Rectangle())
        .contextMenu {
            if let desc = habit.habitDescription, !desc.isEmpty {
                Button(action: { onViewDescription?() }) {
                    Label("View description", systemImage: "text.alignleft")
                }
                Divider()
            }
            Button(action: { onEdit?() }) {
                Label("Edit", systemImage: "pencil")
            }
            Divider()
            Button(role: .destructive, action: { onDelete?() }) {
                Label("Delete", systemImage: "trash")
            }
        }
    }
}

#Preview {
    NavigationStack { DailyView() }.modelContainer(for: Habit.self, inMemory: true)
}
