import SwiftUI
import SwiftData

struct HomeView: View {
    var onPresentTemplates: (() -> Void)?

    @Environment(\.colorScheme) private var colorScheme
    @Query(sort: \Habit.createdAt, order: .reverse) private var allHabits: [Habit]
    @State private var showingAddHabit = false
    @State private var editingHabit: Habit?

    private let config = LayoutConfig.current
    private let calendar = Calendar.current

    private var cardShadowColor: Color { colorScheme == .dark ? .white.opacity(0.04) : .black.opacity(0.05) }
    private var cardShadowRadius: CGFloat { 8 }
    private var cardCornerRadius: CGFloat { 16 }
    private var sectionHeaderPadding: (top: CGFloat, bottom: CGFloat) { (16, 12) }

    /// Current date/time so Home always reflects "today" when the view is evaluated.
    private var today: Date { Date.now }
    private var habits: [Habit] { allHabits }
    private var todayHabits: [Habit] { habits.filter { $0.isActive(on: today) } }
    private var todayIncomplete: [Habit] { todayHabits.filter { !$0.isCompleted(on: today) } }
    /// Habits due today that are done (for progress ring).
    private var todayCompleted: [Habit] { todayHabits.filter { $0.isCompleted(on: today) } }
    /// All habits completed today (any habit you checked off today), so Completed card is never empty when you’ve done something.
    private var habitsCompletedToday: [Habit] { habits.filter { $0.isCompleted(on: today) } }
    private var completedCount: Int { todayCompleted.count }
    private var progress: Double { todayHabits.isEmpty ? 0 : Double(completedCount) / Double(todayHabits.count) }

    /// Due today, not completed, doable now: no reminder time (all day / on command) or scheduled time has arrived.
    private var activeHabits: [Habit] {
        let startOfToday = calendar.startOfDay(for: today)
        return todayIncomplete.filter { habit in
            if habit.reminderTimes.isEmpty { return true }
            guard let first = habit.reminderTimes.first else { return true }
            let scheduledToday = calendar.date(bySettingHour: calendar.component(.hour, from: first), minute: calendar.component(.minute, from: first), second: 0, of: startOfToday)
            guard let scheduled = scheduledToday else { return true }
            return today >= scheduled
        }
    }
    /// Due today, not completed, scheduled for a later time.
    private var scheduledHabits: [Habit] {
        let startOfToday = calendar.startOfDay(for: today)
        return todayIncomplete.filter { habit in
            guard let first = habit.reminderTimes.first else { return false }
            let scheduledToday = calendar.date(bySettingHour: calendar.component(.hour, from: first), minute: calendar.component(.minute, from: first), second: 0, of: startOfToday)
            guard let scheduled = scheduledToday else { return false }
            return today < scheduled
        }
    }

    /// Show floating + only when there’s no Add habit on the page (i.e. when we have habits and we’re not in empty state).
    private var showFloatingAddButton: Bool { !habits.isEmpty && !isEmptyState }

    private var isEmptyState: Bool {
        todayHabits.isEmpty && habitsCompletedToday.isEmpty
    }

    var body: some View {
        NavigationStack {
            Group {
                if isEmptyState {
                    VStack(spacing: 0) {
                        headerSection
                        Spacer(minLength: 0).frame(maxHeight: 48)
                        homeContent
                            .frame(maxWidth: config.contentMaxWidth)
                            .padding(.horizontal, config.horizontalPadding)
                        AdCardView()
                            .frame(maxWidth: config.contentMaxWidth)
                            .padding(.horizontal, config.horizontalPadding)
                            .padding(.top, 24)
                        Spacer(minLength: 0)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                        VStack(spacing: 24) {
                            headerSection
                            homeContent
                            AdCardView()
                                .frame(maxWidth: config.contentMaxWidth)
                                .padding(.horizontal, config.horizontalPadding)
                        }
                        .padding(.bottom, 32)
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.appGroupedBackground)
            .navigationTitle("")
            .inlineNavigationTitle()
            .overlay(alignment: .bottomTrailing) {
                if showFloatingAddButton {
                    Menu {
                        Button {
                            onPresentTemplates?()
                        } label: {
                            Label("From template", systemImage: "square.grid.2x2")
                        }
                        Button {
                            showingAddHabit = true
                        } label: {
                            Label("Add habit", systemImage: "plus.circle")
                        }
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 28))
                            .foregroundStyle(.white)
                            .frame(width: 56, height: 56)
                            .background(Color(red: 0.22, green: 0.45, blue: 0.88), in: Circle())
                            .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
                    }
                    .padding(config.horizontalPadding + 16)
                    .padding(.bottom, 32)
                }
            }
            .sheet(isPresented: $showingAddHabit) { AddEditHabitView() }
            .sheet(item: $editingHabit) { AddEditHabitView(habit: $0) }
        }
    }
    
    // MARK: - Header

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            PageHeading(
                title: today.formatted(.dateTime.weekday(.wide)),
                subtitle: today.formatted(.dateTime.month(.wide).day())
            )
            Text(headerTagline)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .padding(.horizontal, config.horizontalPadding)
                .padding(.top, -4)
                .padding(.bottom, 6)
        }
    }

    private var headerTagline: String {
        if todayHabits.isEmpty && habitsCompletedToday.isEmpty {
            return habits.isEmpty ? "Your day at a glance" : "All set for today"
        }
        if todayHabits.isEmpty {
            return "\(habitsCompletedToday.count) completed today"
        }
        if completedCount == todayHabits.count {
            return "All \(todayHabits.count) done — great job!"
        }
        return "\(completedCount) of \(todayHabits.count) done"
    }

    // MARK: - Home Content (Active, Scheduled, Completed cards)

    private var homeContent: some View {
        Group {
            if todayHabits.isEmpty && habitsCompletedToday.isEmpty {
                HomeEmptyState(
                    icon: "checkmark.circle",
                    iconColor: .green,
                    title: habits.isEmpty ? "No habits yet" : "All caught up",
                    message: habits.isEmpty ? "Create your first habit or start from a template." : "No habits due today. Tap + to add one.",
                    primaryButtonTitle: "New",
                    primaryButtonAction: { showingAddHabit = true },
                    secondaryButtonTitle: "From template",
                    secondaryButtonAction: { onPresentTemplates?() }
                )
            } else {
                VStack(spacing: 16) {
                    if !todayHabits.isEmpty {
                        activeCard
                    } else if !habitsCompletedToday.isEmpty {
                        Text("No habits due today")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                    }
                    if !scheduledHabits.isEmpty {
                        scheduledCard
                    }
                    if !habitsCompletedToday.isEmpty {
                        completedCard
                    }
                }
            }
        }
    }

    private var activeCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            progressHeader
                .padding(.horizontal, 20)
                .padding(.top, 22)
                .padding(.bottom, 16)
            Divider()
                .padding(.leading, 112)
                .padding(.horizontal, 20)
            if activeHabits.isEmpty {
                Text("All done!")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(activeHabits.enumerated()), id: \.element.id) { index, habit in
                        ChecklistRow(habit: habit, date: today, onEdit: { editingHabit = habit }, onDelete: { deleteHabit(habit) })
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                        if index < activeHabits.count - 1 {
                            Divider()
                                .padding(.leading, 96)
                        }
                    }
                }
            }
        }
        .background(Color.secondarySystemGroupedBackground)
        .clipShape(RoundedRectangle(cornerRadius: cardCornerRadius))
        .overlay(
            RoundedRectangle(cornerRadius: cardCornerRadius)
                .stroke(Color.primary.opacity(colorScheme == .dark ? 0.08 : 0.05), lineWidth: 1)
        )
        .shadow(color: cardShadowColor, radius: cardShadowRadius, x: 0, y: 3)
        .frame(maxWidth: config.contentMaxWidth)
        .padding(.horizontal, config.horizontalPadding)
    }

    private var scheduledCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 8) {
                Image(systemName: "clock.fill")
                    .font(.system(size: 16))
                    .foregroundStyle(.orange)
                Text("Scheduled")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.top, sectionHeaderPadding.top)
            .padding(.bottom, sectionHeaderPadding.bottom)
            VStack(spacing: 0) {
                ForEach(Array(scheduledHabits.enumerated()), id: \.element.id) { index, habit in
                    ScheduledRow(habit: habit, onEdit: { editingHabit = habit }, onDelete: { deleteHabit(habit) })
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                    if index < scheduledHabits.count - 1 {
                        Divider()
                            .padding(.leading, 96)
                    }
                }
            }
        }
        .background(Color.secondarySystemGroupedBackground)
        .clipShape(RoundedRectangle(cornerRadius: cardCornerRadius))
        .overlay(
            RoundedRectangle(cornerRadius: cardCornerRadius)
                .stroke(Color.primary.opacity(colorScheme == .dark ? 0.08 : 0.05), lineWidth: 1)
        )
        .shadow(color: cardShadowColor, radius: cardShadowRadius, x: 0, y: 3)
        .frame(maxWidth: config.contentMaxWidth)
        .padding(.horizontal, config.horizontalPadding)
    }

    private var completedCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 8) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 16))
                    .foregroundStyle(.green)
                Text("Completed")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.top, sectionHeaderPadding.top)
            .padding(.bottom, sectionHeaderPadding.bottom)
            VStack(spacing: 0) {
                ForEach(Array(habitsCompletedToday.enumerated()), id: \.element.id) { index, habit in
                    ChecklistRow(habit: habit, date: today, onEdit: { editingHabit = habit }, onDelete: { deleteHabit(habit) })
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                    if index < habitsCompletedToday.count - 1 {
                        Divider()
                            .padding(.leading, 96)
                    }
                }
            }
        }
        .background(Color.secondarySystemGroupedBackground)
        .clipShape(RoundedRectangle(cornerRadius: cardCornerRadius))
        .overlay(
            RoundedRectangle(cornerRadius: cardCornerRadius)
                .stroke(Color.primary.opacity(colorScheme == .dark ? 0.08 : 0.05), lineWidth: 1)
        )
        .shadow(color: cardShadowColor, radius: cardShadowRadius, x: 0, y: 3)
        .frame(maxWidth: config.contentMaxWidth)
        .padding(.horizontal, config.horizontalPadding)
    }

    private var progressHeader: some View {
        HStack(spacing: 20) {
            ProgressRing(progress: progress, count: completedCount, total: todayHabits.count, size: 72)
            VStack(alignment: .leading, spacing: 4) {
                Text("\(completedCount) of \(todayHabits.count) done")
                    .font(.headline.weight(.semibold))
                Text(motivationalMessage)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer()
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

