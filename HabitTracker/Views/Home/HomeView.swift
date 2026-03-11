import SwiftUI
import SwiftData

struct HomeView: View {
    var onPresentTemplates: (() -> Void)?

    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject private var accountMenuState: AccountMenuState
    @Query(sort: \Habit.createdAt, order: .reverse) private var allHabits: [Habit]
    @State private var showingAddHabit = false
    @State private var showingAddMenuPopover = false
    @State private var editingHabit: Habit?
    @State private var habitForDetailsSheet: Habit?
    @State private var skipReasonTarget: (habit: Habit, date: Date)?
    @State private var skipReasonAlertMessage: String?

    private let config = LayoutConfig.current
    private let calendar = Calendar.current

    private var cardShadowColor: Color { colorScheme == .dark ? .white.opacity(0.04) : .black.opacity(0.05) }

    /// Current date/time so Home always reflects "today" when the view is evaluated.
    private var today: Date { Date.now }
    private var habits: [Habit] { allHabits }
    private var todayHabits: [Habit] { habits.filter { $0.isActive(on: today) } }
    private var todayIncomplete: [Habit] { todayHabits.filter { !$0.isCompleted(on: today) } }
    /// Habits due today that are done (for progress ring).
    private var todayCompleted: [Habit] { todayHabits.filter { $0.isCompleted(on: today) } }
    /// All habits completed today (any habit you checked off today), so Completed card is never empty when you’ve done something.
    private var habitsCompletedToday: [Habit] { habits.filter { $0.isCompleted(on: today) } }
    private var uniqueNamesActiveToday: Set<String> { Set(todayHabits.map(\.name)) }
    private var uniqueNamesCompletedToday: Set<String> { Set(habitsCompletedToday.map(\.name)) }
    private var completedCount: Int { uniqueNamesCompletedToday.count }
    private var progress: Double {
        let total = uniqueNamesActiveToday.count
        return total == 0 ? 0 : Double(completedCount) / Double(total)
    }

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

    /// One row per habit name in Active; exclude names already completed today.
    private var activeHabitsDisplay: [Habit] {
        let completedNames = uniqueNamesCompletedToday
        let grouped = Dictionary(grouping: activeHabits.filter { !completedNames.contains($0.name) }, by: \.name)
        return grouped.compactMap { _, group in group.first }.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }
    /// One row per habit name in Scheduled; exclude names completed today.
    private var scheduledHabitsDisplay: [Habit] {
        let completedNames = uniqueNamesCompletedToday
        let grouped = Dictionary(grouping: scheduledHabits.filter { !completedNames.contains($0.name) }, by: \.name)
        return grouped.compactMap { _, group in group.first }.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }
    /// One row per habit name in Completed.
    private var habitsCompletedTodayDisplay: [Habit] {
        let grouped = Dictionary(grouping: habitsCompletedToday, by: \.name)
        return grouped.compactMap { _, group in group.first }.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    /// Show floating + only when there’s no Add habit on the page (i.e. when we have habits and we’re not in empty state).
    private var showFloatingAddButton: Bool { !habits.isEmpty && !isEmptyState }

    private var isEmptyState: Bool {
        uniqueNamesActiveToday.isEmpty && uniqueNamesCompletedToday.isEmpty
    }

    var body: some View {
        NavigationStack {
            Group {
                if isEmptyState {
                    VStack(alignment: .leading, spacing: 0) {
                        headerSection
                        Spacer(minLength: 0).frame(maxHeight: 48)
                        homeContent
                            .frame(maxWidth: config.contentMaxWidth)
                            .padding(.horizontal, config.horizontalPadding)
                        #if os(iOS)
                        AdCardView()
                            .frame(maxWidth: config.contentMaxWidth)
                            .padding(.horizontal, config.horizontalPadding)
                            .padding(.top, config.spacingXXL)
                        #endif
                        Spacer(minLength: 0)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                        VStack(alignment: .leading, spacing: config.spacingXXL) {
                            headerSection
                            homeContent
                            #if os(iOS)
                            AdCardView()
                                .frame(maxWidth: config.contentMaxWidth)
                                .padding(.horizontal, config.horizontalPadding)
                            #endif
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.bottom, config.spacingXXL + config.spacingS)
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.appGroupedBackground)
            .navigationTitle("")
            .inlineNavigationTitle()
            .sheet(isPresented: $accountMenuState.showingAccountProfile) {
                AccountProfileView()
            }
            .alert("Sign in", isPresented: Binding(
                get: { accountMenuState.authError != nil },
                set: { if !$0 { accountMenuState.authError = nil } }
            )) {
                Button("OK") { accountMenuState.authError = nil }
            } message: {
                if let error = accountMenuState.authError { Text(error) }
            }
            .overlay(alignment: .bottomTrailing) {
                if showFloatingAddButton {
                    floatingAddButton
                    .padding(.horizontal, config.horizontalPadding + config.spacingL)
                    #if os(macOS)
                    .padding(.bottom, 44)
                    #else
                    .padding(.bottom, 32)
                    #endif
                }
            }
            .sheet(isPresented: $showingAddHabit) { AddEditHabitView() }
            .habitSheets(details: $habitForDetailsSheet, editing: $editingHabit)
            .sheet(item: homeSkipReasonBinding) { pair in
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
    }
    
    private var homeSkipReasonBinding: Binding<SkipReasonSheetItem?> {
        Binding(
            get: { skipReasonTarget.map { SkipReasonSheetItem(habit: $0.habit, date: $0.date) } },
            set: { skipReasonTarget = $0.map { ($0.habit, $0.date) } }
        )
    }

    /// Same blue as iOS so the add button stands out on all platforms.
    private static let floatingButtonBlue = Color(red: 0.22, green: 0.45, blue: 0.88)

    @ViewBuilder
    private var floatingAddButton: some View {
        #if os(macOS)
        Button {
            showingAddMenuPopover = true
        } label: {
            floatingAddButtonLabel
        }
        .buttonStyle(.plain)
        .popover(isPresented: $showingAddMenuPopover, arrowEdge: .bottom) {
            VStack(alignment: .leading, spacing: config.spacingS) {
                Button {
                    showingAddMenuPopover = false
                    onPresentTemplates?()
                } label: {
                    Label("From template", systemImage: "square.grid.2x2")
                        .font(.body.weight(.medium))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, config.spacingM)
                        .padding(.horizontal, config.spacingS)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                Button {
                    showingAddMenuPopover = false
                    showingAddHabit = true
                } label: {
                    Label("Add habit", systemImage: "plus.circle")
                        .font(.body.weight(.medium))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, config.spacingM)
                        .padding(.horizontal, config.spacingS)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
            .padding(config.spacingL)
            .frame(minWidth: 220)
        }
        #else
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
            floatingAddButtonLabel
        }
        .accessibilityLabel("Add habit")
        .accessibilityHint("Double tap to add a new habit or choose from template")
        #endif
    }

    private var floatingAddButtonLabel: some View {
        #if os(macOS)
        Image(systemName: "plus.circle.fill")
            .font(.system(size: config.iconSizeRow + 2))
            .foregroundStyle(.white)
            .frame(width: config.iconSizeButton, height: config.iconSizeButton)
            .background(Self.floatingButtonBlue, in: Circle())
            .overlay(Circle().strokeBorder(.white.opacity(0.4), lineWidth: 1))
            .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
        #else
        Image(systemName: "plus.circle.fill")
            .font(.system(size: config.iconSizeRow + 4))
            .foregroundStyle(.white)
            .frame(width: config.progressRingSize - 16, height: config.progressRingSize - 16)
            .background(Self.floatingButtonBlue, in: Circle())
            .shadow(color: .black.opacity(0.2), radius: config.cardShadowRadius, x: 0, y: 4)
        #endif
    }
    
    // MARK: - Header

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .center, spacing: 0) {
                Text(today.formatted(.dateTime.weekday(.wide)))
                    .font(AppTheme.pageTitleFont)
                    .foregroundStyle(.primary)
                #if os(iOS)
                Spacer(minLength: 0)
                AccountMenuButton(accountMenuState: accountMenuState)
                #endif
            }
            .padding(.horizontal, config.horizontalPadding)
            .padding(.top, AppTheme.headingTopPadding)
            .padding(.bottom, AppTheme.headingSpacing)
            Text(today.formatted(.dateTime.month(.wide).day()))
                .font(AppTheme.pageSubtitleFont)
                .foregroundStyle(.secondary)
                .padding(.horizontal, config.horizontalPadding)
            Text(headerTagline)
                .font(.subheadline)
                .foregroundStyle(.tertiary)
                .padding(.horizontal, config.horizontalPadding)
                .padding(.top, config.spacingS)
                .padding(.bottom, config.cardBottomPaddingSmall)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    /// Line below the date only. Kept separate from the active card so we don’t repeat "X of Y done".
    private var headerTagline: String {
        if habits.isEmpty {
            return "Your day at a glance"
        }
        if uniqueNamesActiveToday.isEmpty {
            return "All set for today"
        }
        return "Your habits for today"
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
                VStack(spacing: config.spacingL) {
                    if !uniqueNamesActiveToday.isEmpty {
                        activeCard
                    } else if !habitsCompletedTodayDisplay.isEmpty {
                        Text("No habits due today")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, config.spacingM)
                    }
                    if !scheduledHabitsDisplay.isEmpty {
                        scheduledCard
                    }
                    if !habitsCompletedTodayDisplay.isEmpty {
                        completedCard
                    }
                }
            }
        }
    }

    private var activeCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            progressHeader
                .padding(.horizontal, config.cardContentPaddingHorizontal)
                .padding(.top, config.progressHeaderTop)
                .padding(.bottom, config.progressHeaderBottom)
            if activeHabitsDisplay.isEmpty {
                Text("All done!")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, config.spacingM + 6)
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(activeHabitsDisplay.enumerated()), id: \.element.id) { index, habit in
                        ChecklistRow(
                            habit: habit,
                            date: today,
                            onEdit: { editingHabit = habit },
                            onDelete: { deleteHabit(habit) },
                            onViewDescription: { habitForDetailsSheet = habit },
                            onUnskip: { HabitStore.shared.unskipDay(for: habit, on: today) },
                            onSkipWithReason: { skipReasonTarget = (habit, today) },
                            onTapSkipReason: { skipReasonAlertMessage = $0 }
                        )
                            .padding(.horizontal, config.cardContentPaddingHorizontal)
                            .padding(.vertical, config.cardRowPaddingVertical)
                    }
                }
            }
        }
        .padding(.bottom, config.cardBottomPaddingExtra)
        .background(Color.secondarySystemGroupedBackground)
        .clipShape(RoundedRectangle(cornerRadius: config.cardCornerRadius))
        .overlay(
            RoundedRectangle(cornerRadius: config.cardCornerRadius)
                .stroke(Color.primary.opacity(cardBorderOpacity), lineWidth: 1)
        )
        .shadow(color: cardShadowColor, radius: config.cardShadowRadius, x: 0, y: 3)
        .frame(maxWidth: config.contentMaxWidth)
        .padding(.horizontal, config.horizontalPadding)
    }

    #if os(macOS)
    private var cardBorderOpacity: Double { colorScheme == .dark ? 0.14 : 0.2 }
    #else
    private var cardBorderOpacity: Double { colorScheme == .dark ? 0.08 : 0.05 }
    #endif

    private var scheduledCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: config.spacingS) {
                Image(systemName: "clock.fill")
                    .font(.system(size: config.spacingL))
                    .foregroundStyle(.orange)
                Text("Scheduled")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
                Spacer()
            }
            .padding(.horizontal, config.cardContentPaddingHorizontal)
            .padding(.top, config.sectionHeaderTop)
            .padding(.bottom, config.sectionHeaderBottom)
            VStack(spacing: 0) {
                ForEach(Array(scheduledHabitsDisplay.enumerated()), id: \.element.id) { index, habit in
                    ScheduledRow(
                        habit: habit,
                        onEdit: { editingHabit = habit },
                        onDelete: { deleteHabit(habit) },
                        onViewDescription: { habitForDetailsSheet = habit }
                    )
                        .padding(.horizontal, config.cardContentPaddingHorizontal)
                        .padding(.vertical, config.cardRowPaddingVertical)
                }
            }
        }
        .padding(.bottom, config.cardBottomPaddingSmall)
        .background(Color.secondarySystemGroupedBackground)
        .clipShape(RoundedRectangle(cornerRadius: config.cardCornerRadius))
        .overlay(
            RoundedRectangle(cornerRadius: config.cardCornerRadius)
                .stroke(Color.primary.opacity(cardBorderOpacity), lineWidth: 1)
        )
        .shadow(color: cardShadowColor, radius: config.cardShadowRadius, x: 0, y: 3)
        .frame(maxWidth: config.contentMaxWidth)
        .padding(.horizontal, config.horizontalPadding)
    }

    private var completedCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: config.spacingS) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: config.spacingL))
                    .foregroundStyle(.green)
                Text("Completed")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
                Spacer()
            }
            .padding(.horizontal, config.cardContentPaddingHorizontal)
            .padding(.top, config.sectionHeaderTop)
            .padding(.bottom, config.sectionHeaderBottom)
            VStack(spacing: 0) {
                    ForEach(Array(habitsCompletedTodayDisplay.enumerated()), id: \.element.id) { index, habit in
                        ChecklistRow(
                            habit: habit,
                            date: today,
                            onEdit: { editingHabit = habit },
                            onDelete: { deleteHabit(habit) },
                            onViewDescription: { habitForDetailsSheet = habit },
                            onUnskip: { HabitStore.shared.unskipDay(for: habit, on: today) },
                            onSkipWithReason: { skipReasonTarget = (habit, today) },
                            onTapSkipReason: { skipReasonAlertMessage = $0 }
                        )
                        .padding(.horizontal, config.cardContentPaddingHorizontal)
                        .padding(.vertical, config.cardRowPaddingVertical)
                }
            }
        }
        .padding(.bottom, config.cardBottomPaddingSmall)
        .background(Color.secondarySystemGroupedBackground)
        .clipShape(RoundedRectangle(cornerRadius: config.cardCornerRadius))
        .overlay(
            RoundedRectangle(cornerRadius: config.cardCornerRadius)
                .stroke(Color.primary.opacity(cardBorderOpacity), lineWidth: 1)
        )
        .shadow(color: cardShadowColor, radius: config.cardShadowRadius, x: 0, y: 3)
        .frame(maxWidth: config.contentMaxWidth)
        .padding(.horizontal, config.horizontalPadding)
    }

    private var progressHeader: some View {
        HStack(spacing: config.spacingXL) {
            ProgressRing(progress: progress, count: completedCount, total: uniqueNamesActiveToday.count, size: config.progressRingSize)
            VStack(alignment: .leading, spacing: config.spacingXS) {
                Text("\(completedCount) of \(uniqueNamesActiveToday.count) done")
                    .font(.headline.weight(.semibold))
                Text(motivationalMessage)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
    }

    private var motivationalMessage: String {
        let total = uniqueNamesActiveToday.count
        if completedCount == total && completedCount > 0 { return "All done! 🎉" }
        if progress >= 0.5 { return "Keep going! 💪" }
        if completedCount > 0 { return "\(total - completedCount) left" }
        return "Let's start! 👋"
    }
    
    private func deleteHabit(_ habit: Habit) {
        NotificationService.shared.removeReminders(for: habit.id)
        HabitStore.shared.deleteHabit(habit)
    }
}

// MARK: - Home empty state (compact, modern)

#Preview {
    HomeView()
        .environmentObject(AccountMenuState())
        .modelContainer(for: Habit.self, inMemory: true)
}

