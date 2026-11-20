import SwiftUI
import SwiftData

struct HomeView: View {
    var onPresentTemplates: (() -> Void)?

    @Environment(\.colorScheme) private var colorScheme
    @Environment(AccountMenuState.self) private var accountMenuState
    @Query(sort: \Habit.createdAt, order: .reverse) private var allHabits: [Habit]
    private var purchases = PurchaseManager.shared
    @State private var showingAddHabit = false
    @State private var showingAddMenuPopover = false
    @State private var editingHabit: Habit?
    @State private var habitForDetailsSheet: Habit?
    @State private var skipReasonTarget: (habit: Habit, date: Date)?
    @State private var skipReasonAlertMessage: String?

    private let config = LayoutConfig.current


    /// Current date/time so Home always reflects "today" when the view is evaluated.
    private var today: Date { Date.now }
    private var habits: [Habit] { allHabits }
    /// All of Home's grouping and progress logic lives in TodaySnapshot (tested). Duplicate habits
    /// are merged in the data layer now, so there's no more grouping by name here.
    private var snapshot: TodaySnapshot { TodaySnapshot(habits: allHabits, now: today) }

    private var todayHabits: [Habit] { snapshot.dueToday }
    private var habitsCompletedToday: [Habit] { snapshot.completed }
    private var completedCount: Int { snapshot.doneCount }
    private var progressTotal: Int { snapshot.actionableCount }
    private var progress: Double { snapshot.progress }

    private var activeHabitsDisplay: [Habit] { snapshot.dueNow }
    private var scheduledHabitsDisplay: [Habit] { snapshot.later }
    private var habitsCompletedTodayDisplay: [Habit] { snapshot.completed }
    private var skippedHabitsDisplay: [Habit] { snapshot.skipped }

    /// Show floating + only when there’s no Add habit on the page (i.e. when we have habits and we’re not in empty state).
    private var showFloatingAddButton: Bool { !habits.isEmpty && !isEmptyState }

    private var isEmptyState: Bool { snapshot.isEmpty }

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
                        if !purchases.isAdFree {
                            AdCardView()
                                .frame(maxWidth: config.contentMaxWidth)
                                .padding(.horizontal, config.horizontalPadding)
                                .padding(.top, config.spacingXXL)
                        }
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
                            if !purchases.isAdFree {
                                AdCardView()
                                    .frame(maxWidth: config.contentMaxWidth)
                                    .padding(.horizontal, config.horizontalPadding)
                            }
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
            .sheet(isPresented: Binding(
                get: { accountMenuState.showingAccountProfile },
                set: { accountMenuState.showingAccountProfile = $0 }
            )) {
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

    @ViewBuilder
    private var floatingAddButtonLabel: some View {
        let icon = Image(systemName: "plus")
            .font(.title2.weight(.semibold))
            .foregroundStyle(.white)
            .frame(width: 56, height: 56)
        if #available(iOS 26.0, macOS 26.0, *) {
            icon.glassEffect(.regular.tint(.accentColor).interactive(), in: .circle)
        } else {
            icon
                .background(Color.accentColor, in: Circle())
                .shadow(color: .black.opacity(0.2), radius: 6, x: 0, y: 3)
        }
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
        if todayHabits.isEmpty {
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
                    if !todayHabits.isEmpty {
                        activeCard
                    } else if !habitsCompletedTodayDisplay.isEmpty || !skippedHabitsDisplay.isEmpty {
                        noHabitsDueTodayLine
                    }
                    if !scheduledHabitsDisplay.isEmpty {
                        scheduledCard
                    }
                    if !skippedHabitsDisplay.isEmpty {
                        skippedCard
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
        .frame(maxWidth: config.contentMaxWidth)
        .padding(.horizontal, config.horizontalPadding)
    }

    private var progressHeader: some View {
        HStack(spacing: config.spacingXL) {
            ProgressRing(progress: progress, count: completedCount, total: progressTotal, size: config.progressRingSize)
            VStack(alignment: .leading, spacing: config.spacingXS) {
                Text(progressTotal == 0 ? "0 of 0 done" : "\(completedCount) of \(progressTotal) done")
                    .font(.headline.weight(.semibold))
                    .contentTransition(.numericText())
                Text(motivationalMessage)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
    }

    private var noHabitsDueTodayLine: some View {
        VStack(spacing: config.spacingXS) {
            Text("0 of 0 done")
                .font(.headline.weight(.semibold))
            Text("No habits due today")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, config.spacingM)
    }

    private var skippedCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: config.spacingS) {
                Image(systemName: "pause.circle.fill")
                    .font(.system(size: config.spacingL))
                    .foregroundStyle(.orange)
                Text("Skipped")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
                Spacer()
            }
            .padding(.horizontal, config.cardContentPaddingHorizontal)
            .padding(.top, config.sectionHeaderTop)
            .padding(.bottom, config.sectionHeaderBottom)
            VStack(spacing: 0) {
                ForEach(Array(skippedHabitsDisplay.enumerated()), id: \.element.id) { _, habit in
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
        .frame(maxWidth: config.contentMaxWidth)
        .padding(.horizontal, config.horizontalPadding)
    }

    private var motivationalMessage: String {
        let total = progressTotal
        if completedCount == total && completedCount > 0 { return "All done! 🎉" }
        if progress >= 0.5 { return "Keep going! 💪" }
        if completedCount > 0 { return "\(total - completedCount) left" }
        return "Let's start! 👋"
    }
    
    private func deleteHabit(_ habit: Habit) {
        HabitStore.shared.deleteHabit(habit)
    }
}

// MARK: - Home empty state (compact, modern)

#Preview {
    HomeView()
        .environment(AccountMenuState())
        .environment(ModelContainerProvider.shared)
        .modelContainer(for: Habit.self, inMemory: true)
}

