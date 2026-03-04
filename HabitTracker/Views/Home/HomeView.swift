import SwiftUI
import SwiftData

struct HomeView: View {
    @Query(sort: \Habit.createdAt, order: .reverse) private var allHabits: [Habit]
    @State private var showingAddHabit = false
    @State private var selectedTab: HomeTab = .active
    @State private var editingHabit: Habit?
    
    private let config = LayoutConfig.current
    
    enum HomeTab: String, CaseIterable {
        case active = "Active"
        case all = "All Habits"
    }
    
    private let today = Date.now
    private var habits: [Habit] { allHabits.filter { !$0.isArchived } }
    private var todayHabits: [Habit] { habits.filter { $0.isActive(on: today) } }
    private var completedCount: Int { todayHabits.filter { $0.isCompleted(on: today) }.count }
    private var progress: Double { todayHabits.isEmpty ? 0 : Double(completedCount) / Double(todayHabits.count) }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 28) {
                    headerSection
                    segmentedPicker
                    
                    if selectedTab == .active {
                        activeSection
                    } else {
                        allHabitsSection
                    }
                }
                .padding(.bottom, 32)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.systemGroupedBackground)
            .inlineNavigationTitle()
            .toolbar { }
            .sheet(isPresented: $showingAddHabit) { AddEditHabitView() }
            .sheet(item: $editingHabit) { AddEditHabitView(habit: $0) }
        }
    }
    
    // MARK: - Header
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Today")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.secondary)
            Text(today.formatted(.dateTime.weekday(.wide)))
                .font(.system(size: 28, weight: .bold, design: .rounded))
            Text(today.formatted(.dateTime.month(.wide).day()))
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: config.contentMaxWidth, alignment: .leading)
        .padding(.horizontal, config.horizontalPadding)
        .padding(.top, 20)
    }
    
    // MARK: - Segmented Picker
    
    private var segmentedPicker: some View {
        Picker("", selection: $selectedTab) {
            ForEach(HomeTab.allCases, id: \.self) { Text($0.rawValue).tag($0) }
        }
        .pickerStyle(.segmented)
        .controlSize(.large)
        .labelsHidden()
        .padding(.horizontal, config.horizontalPadding)
        .frame(maxWidth: config.contentMaxWidth)
    }
    
    // MARK: - Active Section
    
    private var activeSection: some View {
        Group {
            if todayHabits.isEmpty {
                HomeEmptyState(
                    icon: "checkmark.circle",
                    iconColor: .green,
                    title: habits.isEmpty ? "No habits yet" : "All caught up",
                    message: habits.isEmpty ? "Create your first habit to start tracking." : "No habits scheduled for today.",
                    buttonTitle: "Add Habit",
                    buttonAction: { showingAddHabit = true }
                )
            } else {
                VStack(spacing: 0) {
                    progressHeader
                    Divider()
                        .padding(.leading, 96)
                    checklistItems
                }
                .background(Color.secondarySystemGroupedBackground)
                .clipShape(RoundedRectangle(cornerRadius: config.cardCornerRadius))
                .frame(maxWidth: config.contentMaxWidth)
                .padding(.horizontal, config.horizontalPadding)
            }
        }
    }
    
    private var progressHeader: some View {
        HStack(spacing: 20) {
            ProgressRing(progress: progress, count: completedCount, total: todayHabits.count, size: 64)
            VStack(alignment: .leading, spacing: 4) {
                Text("\(completedCount) of \(todayHabits.count) done")
                    .font(.headline.weight(.semibold))
                Text(motivationalMessage)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(20)
    }
    
    private var checklistItems: some View {
        ForEach(Array(todayHabits.enumerated()), id: \.element.id) { index, habit in
            ChecklistRow(habit: habit, date: today, onEdit: { editingHabit = habit }, onDelete: { deleteHabit(habit) })
            if index < todayHabits.count - 1 {
                Divider().padding(.leading, 96)
            }
        }
    }
    
    // MARK: - All Habits Section
    
    private var allHabitsSection: some View {
        Group {
            if habits.isEmpty {
                HomeEmptyState(
                    icon: "square.grid.2x2",
                    iconColor: .purple,
                    title: "No habits yet",
                    message: "Create your first habit to see it here.",
                    buttonTitle: "Add Habit",
                    buttonAction: { showingAddHabit = true }
                )
            } else {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 14) {
                    ForEach(habits) { habit in
                        HabitGridCard(habit: habit, onEdit: { editingHabit = habit }, onDelete: { deleteHabit(habit) })
                    }
                }
                .frame(maxWidth: config.contentMaxWidth)
                .padding(.horizontal, config.horizontalPadding)
            }
        }
    }
    
    private var motivationalMessage: String {
        if completedCount == todayHabits.count && completedCount > 0 { return "All done! 🎉" }
        if progress >= 0.5 { return "Keep going! 💪" }
        if completedCount > 0 { return "\(todayHabits.count - completedCount) left" }
        return "Let's start! 👋"
    }
    
    private func deleteHabit(_ habit: Habit) {
        NotificationService.shared.removeReminders(for: habit.id)
        HabitStore.shared.deleteHabit(habit)
    }
}

// MARK: - Home empty state (compact, modern)

#Preview {
    HomeView().modelContainer(for: Habit.self, inMemory: true)
}

