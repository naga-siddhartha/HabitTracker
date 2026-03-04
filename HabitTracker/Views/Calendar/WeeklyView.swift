import SwiftUI
import SwiftData

struct WeeklyView: View {
    @Query(sort: \Habit.createdAt, order: .reverse) private var habits: [Habit]
    @State private var currentWeekStart = Date.now.startOfWeek ?? Date.now
    @State private var showingDescriptionSheet = false
    @State private var descriptionSheetTitle = ""
    @State private var descriptionSheetText = ""
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
                GeometryReader { geo in
                    let horizontalPadding: CGFloat = 16
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
                                        onViewDescription: habit.habitDescription.flatMap { d in d.isEmpty ? nil : { descriptionSheetTitle = habit.name; descriptionSheetText = d; showingDescriptionSheet = true } },
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
            .padding(.bottom, 12)
        }
        .background(Color.systemGray6)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .contentShape(Rectangle())
        .contextMenu {
            if habit.habitDescription.flatMap({ !$0.isEmpty }) == true {
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
