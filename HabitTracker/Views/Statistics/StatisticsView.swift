import SwiftUI
import SwiftData

struct StatisticsView: View {
    @Query(sort: \Habit.createdAt, order: .reverse) private var habits: [Habit]
    @State private var selectedTimeframe: Timeframe = .allTime
    @State private var showingCompletionsDetail = false
    @State private var showingStreaksDetail = false
    @State private var showingHabitsDetail = false
    
    // Cached stats
    @State private var cachedCompletions = 0
    @State private var cachedActiveStreaks = 0
    
    private let config = LayoutConfig.current
    
    enum Timeframe: String, CaseIterable {
        case week = "Week", month = "Month", year = "Year", allTime = "All Time"
    }
    
    private var dateRange: (start: Date, end: Date) {
        let now = Date.now
        switch selectedTimeframe {
        case .week: return (now.startOfWeek ?? now, now.endOfWeek ?? now)
        case .month: return (now.startOfMonth ?? now, now.endOfMonth ?? now)
        case .year: return (now.startOfYear ?? now, now.endOfYear ?? now)
        case .allTime: return (.distantPast, now)
        }
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: config.spacingXXL) {
                    PageHeading(title: "Statistics")

                    // Contribution Graph
                    VStack(alignment: .leading, spacing: config.spacingM) {
                        Text("Activity")
                            .font(.headline)
                            .padding(.horizontal, config.horizontalPadding)
                        ContributionGraphView(weeks: 26)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    
                    VStack(alignment: .leading, spacing: config.spacingM) {
                        Text("Summary")
                            .font(.headline)
                            .padding(.horizontal, config.horizontalPadding)
                        Picker("Timeframe", selection: $selectedTimeframe) {
                            ForEach(Timeframe.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                        }
                        .pickerStyle(.segmented)
                        .padding(.horizontal, config.horizontalPadding)
                    }

                    VStack(spacing: config.spacingL) {
                        Button {
                            showingHabitsDetail = true
                        } label: {
                            StatCard(title: "Total Habits", value: "\(uniqueHabitNamesCount)", icon: "list.bullet", color: .blue)
                        }
                        .buttonStyle(.plain)
                        
                        Button {
                            showingCompletionsDetail = true
                        } label: {
                            StatCard(title: "Total Completions", value: "\(cachedCompletions)", icon: "checkmark.circle.fill", color: .green)
                        }
                        .buttonStyle(.plain)
                        
                        Button {
                            showingStreaksDetail = true
                        } label: {
                            StatCard(title: "Current Streaks", value: "\(cachedActiveStreaks)", icon: "flame.fill", color: .orange)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, config.horizontalPadding)
                    
                    // Top habits
                    StatsSectionCard(
                        title: "Top Performing Habits",
                        icon: "chart.bar.fill",
                        iconColor: .green,
                        isEmpty: topHabitsWithCompletions.isEmpty
                    ) {
                        ForEach(topHabitsWithCompletions.prefix(5), id: \.habit.id) { item in
                            HabitStatRow(habit: item.habit, dateRange: dateRange, displayCount: item.count)
                        }
                    } emptyContent: {
                        StatsEmptyState(
                            icon: "chart.bar",
                            title: "No completions yet",
                            message: "Complete habits in your chosen timeframe to see them here."
                        )
                    }
                    
                    // Streaks
                    StatsSectionCard(
                        title: "Longest Streaks",
                        icon: "flame.fill",
                        iconColor: .orange,
                        isEmpty: habitsWithStreaks.isEmpty
                    ) {
                        ForEach(habitsWithStreaks.prefix(5)) { habit in
                            StreakRow(habit: habit)
                        }
                    } emptyContent: {
                        StatsEmptyState(
                            icon: "flame",
                            title: "No streaks yet",
                            message: "Keep completing habits on consecutive days to build streaks."
                        )
                    }
                }
                .padding(.bottom, config.spacingXXL + config.spacingS)
            }
            .navigationTitle("")
            .inlineNavigationTitle()
            .sheet(isPresented: $showingCompletionsDetail) { CompletionsDetailView(habits: habits, dateRange: dateRange) }
            .sheet(isPresented: $showingStreaksDetail) { StreaksDetailView(habits: habits) }
            .sheet(isPresented: $showingHabitsDetail) { HabitsDetailView(habits: habits) }
            .onAppear { computeStats() }
            .onChange(of: selectedTimeframe) { computeStats() }
            .onChange(of: habits.count) { computeStats() }
        }
    }
    
    private var uniqueHabitNamesCount: Int {
        Set(habits.map(\.name)).count
    }
    
    private func computeStats() {
        let range = dateRange
        let completions = habits.reduce(0) { total, habit in
            total + habit.entriesOrEmpty.filter {
                $0.isCompleted && $0.date >= range.start && $0.date <= range.end
            }.count
        }
        let namesWithStreak = Set(habits.filter { ($0.streak?.currentStreak ?? 0) > 0 }.map(\.name))
        cachedCompletions = completions
        cachedActiveStreaks = namesWithStreak.count
    }
    
    /// One per habit name (duplicates merged), sorted by total completions in date range.
    private var topHabitsWithCompletions: [(habit: Habit, count: Int)] {
        let range = dateRange
        let grouped = Dictionary(grouping: habits, by: \.name)
        return grouped.compactMap { _, group -> (Habit, Int)? in
            guard let first = group.first else { return nil }
            let total = group.reduce(0) { sum, h in
                sum + h.entriesOrEmpty.filter { $0.isCompleted && $0.date >= range.start && $0.date <= range.end }.count
            }
            guard total > 0 else { return nil }
            return (first, total)
        }.sorted { $0.count > $1.count }
    }
    
    /// One per habit name (duplicates merged), sorted by longest streak.
    private var habitsWithStreaks: [Habit] {
        let grouped = Dictionary(grouping: habits.filter { ($0.streak?.longestStreak ?? 0) > 0 }, by: \.name)
        return grouped.compactMap { _, group in
            group.max(by: { ($0.streak?.longestStreak ?? 0) < ($1.streak?.longestStreak ?? 0) })
        }.sorted { ($0.streak?.longestStreak ?? 0) > ($1.streak?.longestStreak ?? 0) }
    }
}

struct CompletionsDetailView: View {
    @Environment(\.dismiss) private var dismiss
    let habits: [Habit]
    let dateRange: (start: Date, end: Date)
    
    /// One row per habit name; duplicates (e.g. same habit added again) are merged with summed completions.
    private var habitsByName: [(habit: Habit, totalCompletions: Int)] {
        let grouped = Dictionary(grouping: habits, by: \.name)
        return grouped.compactMap { name, group in
            guard let first = group.first else { return nil }
            let total = group.reduce(0) { sum, h in
                sum + h.entriesOrEmpty.filter { $0.isCompleted && $0.date >= dateRange.start && $0.date <= dateRange.end }.count
            }
            return (first, total)
        }.sorted { $0.totalCompletions > $1.totalCompletions }
    }
    
    var body: some View {
        NavigationStack {
            List(habitsByName, id: \.habit.id) { item in
                LabeledContent {
                    Text("\(item.totalCompletions) completions").foregroundStyle(.secondary)
                } label: {
                    Label(item.habit.name, systemImage: "circle.fill").foregroundStyle(item.habit.displayColor)
                }
            }
            .navigationTitle("Completions")
            .inlineNavigationTitle()
            .toolbar { Button("Done") { dismiss() } }
            #if os(macOS)
            .frame(minWidth: 320, minHeight: 300)
            #endif
        }
    }
}

struct StreaksDetailView: View {
    @Environment(\.dismiss) private var dismiss
    let habits: [Habit]
    private let config = LayoutConfig.current
    
    /// One row per habit name; duplicates merged, showing the best streak among same-named habits.
    private var habitsByBestStreak: [(habit: Habit, current: Int, longest: Int)] {
        let grouped = Dictionary(grouping: habits, by: \.name)
        return grouped.compactMap { name, group in
            guard let best = group.max(by: { ($0.streak?.longestStreak ?? 0) < ($1.streak?.longestStreak ?? 0) }),
                  let streak = best.streak, streak.longestStreak > 0 else { return nil }
            let bestCurrent = group.map { $0.streak?.currentStreak ?? 0 }.max() ?? 0
            let bestLongest = group.map { $0.streak?.longestStreak ?? 0 }.max() ?? 0
            return (best, bestCurrent, bestLongest)
        }.sorted { $0.longest > $1.longest }
    }
    
    var body: some View {
        NavigationStack {
            List(habitsByBestStreak, id: \.habit.id) { item in
                VStack(alignment: .leading, spacing: config.spacingS) {
                    Label(item.habit.name, systemImage: "circle.fill").foregroundStyle(item.habit.displayColor).font(.headline)
                    HStack {
                        Label("\(item.current) current", systemImage: "flame.fill").foregroundStyle(.orange)
                        Spacer()
                        Label("\(item.longest) longest", systemImage: "trophy.fill").foregroundStyle(.yellow)
                    }
                    .font(.caption)
                }
            }
            .navigationTitle("Streaks")
            .inlineNavigationTitle()
            .toolbar { Button("Done") { dismiss() } }
            #if os(macOS)
            .frame(minWidth: 320, minHeight: 300)
            #endif
        }
    }
}

struct HabitsDetailView: View {
    @Environment(\.dismiss) private var dismiss
    let habits: [Habit]
    private let config = LayoutConfig.current
    
    /// One row per habit name; duplicates merged, using first habit for display.
    private var habitsByName: [Habit] {
        let grouped = Dictionary(grouping: habits, by: \.name)
        return grouped.compactMap { _, group in group.first }.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }
    
    var body: some View {
        NavigationStack {
            List(habitsByName) { habit in
                VStack(alignment: .leading, spacing: config.spacingS) {
                    HStack(spacing: config.spacingS) {
                        if let emoji = habit.emoji, !emoji.isEmpty {
                            Text(emoji).font(.headline)
                        } else {
                            Image(systemName: habit.iconName ?? "circle.fill")
                                .foregroundStyle(habit.displayColor)
                        }
                        Text(habit.name).font(.headline).foregroundStyle(habit.displayColor)
                    }
                    Text("Frequency: \(habit.frequency.rawValue.capitalized)").font(.caption).foregroundStyle(.secondary)
                    if let streak = habit.streak {
                        Text("Current streak: \(streak.currentStreak) days").font(.caption).foregroundStyle(.orange)
                    }
                    Text("Created: \(habit.createdAt.mediumDateString)").font(.caption2).foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Habits")
            .inlineNavigationTitle()
            .toolbar { Button("Done") { dismiss() } }
            #if os(macOS)
            .frame(minWidth: 320, minHeight: 300)
            #endif
        }
    }
}

struct StatCard: View {
    let title: String, value: String, icon: String, color: Color
    private let config = LayoutConfig.current
    
    var body: some View {
        HStack {
            Image(systemName: icon).foregroundStyle(color).font(.title2).frame(width: 40)
            VStack(alignment: .leading, spacing: config.spacingXS) {
                Text(title).font(.subheadline).foregroundStyle(.secondary)
                Text(value).font(.title2).bold()
            }
            Spacer()
            Image(systemName: "chevron.right").foregroundStyle(.secondary).font(.caption)
        }
        .padding(config.spacingL)
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
        .background(Color.systemGray6)
        .clipShape(RoundedRectangle(cornerRadius: config.cornerRadiusMedium))
        .cardBorder(cornerRadius: config.cornerRadiusMedium)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(title)
        .accessibilityValue(value)
        .accessibilityHint("Double tap to view details")
    }
}

struct HabitStatRow: View {
    let habit: Habit
    let dateRange: (start: Date, end: Date)
    /// When set (e.g. when merging duplicate habit names), this count is shown instead of computing from habit + dateRange.
    var displayCount: Int? = nil

    private var count: Int {
        displayCount ?? habit.entriesOrEmpty.filter { $0.isCompleted && $0.date >= dateRange.start && $0.date <= dateRange.end }.count
    }

    var body: some View {
        HStack {
            if let emoji = habit.emoji, !emoji.isEmpty {
                Text(emoji).font(.subheadline)
            } else {
                Circle().fill(habit.displayColor).frame(width: 12, height: 12)
            }
            Text(habit.name).font(.subheadline)
            Spacer()
            Text("\(count) completions").font(.caption).foregroundStyle(.secondary)
        }
        .padding(.horizontal)
    }
}

struct StreakRow: View {
    let habit: Habit
    
    var body: some View {
        HStack {
            if let emoji = habit.emoji, !emoji.isEmpty {
                Text(emoji).font(.subheadline)
            } else {
                Circle().fill(habit.displayColor).frame(width: 12, height: 12)
            }
            Text(habit.name).font(.subheadline)
            Spacer()
            Label("\(habit.streak?.longestStreak ?? 0) days", systemImage: "flame.fill")
                .font(.caption).foregroundStyle(.orange)
        }
        .padding(.horizontal)
    }
}

// MARK: - Stats section card (modular, sleek empty/content)

struct StatsSectionCard<Content: View, EmptyContent: View>: View {
    let title: String
    let icon: String
    let iconColor: Color
    let isEmpty: Bool
    @ViewBuilder let content: () -> Content
    @ViewBuilder let emptyContent: () -> EmptyContent
    
    private let config = LayoutConfig.current
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: config.spacingS) {
                Image(systemName: icon)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(iconColor)
                Text(title)
                    .font(.headline)
            }
            .padding(.horizontal, config.horizontalPadding)
            .padding(.top, config.spacingL)
            .padding(.bottom, config.spacingM)
            
            if isEmpty {
                emptyContent()
            } else {
                VStack(spacing: 0) {
                    content()
                }
                .padding(.horizontal, config.spacingL)
                .padding(.bottom, config.spacingL)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.systemGray6)
        .clipShape(RoundedRectangle(cornerRadius: config.cardCornerRadius))
        .cardBorder(cornerRadius: config.cardCornerRadius)
        .padding(.horizontal, config.horizontalPadding)
    }
}

struct StatsEmptyState: View {
    let icon: String
    let title: String
    let message: String
    
    private let config = LayoutConfig.current
    
    var body: some View {
        VStack(spacing: config.cardRowPaddingVertical) {
            Image(systemName: icon)
                .font(.system(size: config.iconSizeRow))
                .foregroundStyle(.secondary.opacity(0.8))
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)
            Text(message)
                .font(.caption)
                .foregroundStyle(.secondary.opacity(0.8))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, config.spacingXXL)
        .padding(.horizontal, config.horizontalPadding)
    }
}

#Preview {
    StatisticsView()
        .modelContainer(for: Habit.self, inMemory: true)
}
