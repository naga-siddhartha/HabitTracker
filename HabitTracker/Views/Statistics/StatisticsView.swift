import SwiftUI
import SwiftData

struct StatisticsView: View {
    @Query(filter: #Predicate<Habit> { !$0.isArchived }) private var habits: [Habit]
    @State private var selectedTimeframe: Timeframe = .allTime
    @State private var showingCompletionsDetail = false
    @State private var showingStreaksDetail = false
    @State private var showingHabitsDetail = false
    
    // Cached stats
    @State private var cachedCompletions = 0
    @State private var cachedActiveStreaks = 0
    
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
                VStack(spacing: 24) {
                    PageHeading(title: "Statistics")

                    // Contribution Graph
                    VStack(alignment: .center, spacing: 8) {
                        Text("Activity")
                            .font(.headline)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal)
                        
                        ContributionGraphView(weeks: 26)
                    }
                    
                    Picker("Timeframe", selection: $selectedTimeframe) {
                        ForEach(Timeframe.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)
                    
                    VStack(spacing: 16) {
                        StatCard(title: "Total Habits", value: "\(habits.count)", icon: "list.bullet", color: .blue)
                            .onTapGesture { showingHabitsDetail = true }
                        
                        StatCard(title: "Total Completions", value: "\(cachedCompletions)", icon: "checkmark.circle.fill", color: .green)
                            .onTapGesture { showingCompletionsDetail = true }
                        
                        StatCard(title: "Current Streaks", value: "\(cachedActiveStreaks)", icon: "flame.fill", color: .orange)
                            .onTapGesture { showingStreaksDetail = true }
                    }
                    .padding(.horizontal)
                    
                    // Top habits
                    StatsSectionCard(
                        title: "Top Performing Habits",
                        icon: "chart.bar.fill",
                        iconColor: .green,
                        isEmpty: topHabitsWithCompletions.isEmpty
                    ) {
                        ForEach(topHabitsWithCompletions.prefix(5)) { habit in
                            HabitStatRow(habit: habit, dateRange: dateRange)
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
                .padding(.bottom, 32)
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
    
    private func computeStats() {
        let range = dateRange
        let completions = habits.reduce(0) { total, habit in
            total + habit.entries.filter {
                $0.isCompleted && $0.date >= range.start && $0.date <= range.end
            }.count
        }
        let streaks = habits.filter { ($0.streak?.currentStreak ?? 0) > 0 }.count
        
        cachedCompletions = completions
        cachedActiveStreaks = streaks
    }
    
    private var topHabitsWithCompletions: [Habit] {
        let range = dateRange
        return habits
            .filter { habit in
                habit.entries.contains { $0.isCompleted && $0.date >= range.start && $0.date <= range.end }
            }
            .sorted { a, b in
                a.entries.lazy.filter { $0.isCompleted && $0.date >= range.start && $0.date <= range.end }.count >
                b.entries.lazy.filter { $0.isCompleted && $0.date >= range.start && $0.date <= range.end }.count
            }
    }
    
    private var habitsWithStreaks: [Habit] {
        habits.filter { ($0.streak?.longestStreak ?? 0) > 0 }
            .sorted { ($0.streak?.longestStreak ?? 0) > ($1.streak?.longestStreak ?? 0) }
    }
}

struct CompletionsDetailView: View {
    @Environment(\.dismiss) private var dismiss
    let habits: [Habit]
    let dateRange: (start: Date, end: Date)
    
    var body: some View {
        NavigationStack {
            List(habits) { habit in
                let count = habit.entries.filter { $0.isCompleted && $0.date >= dateRange.start && $0.date <= dateRange.end }.count
                LabeledContent {
                    Text("\(count) completions").foregroundStyle(.secondary)
                } label: {
                    Label(habit.name, systemImage: "circle.fill").foregroundStyle(habit.color.color)
                }
            }
            .navigationTitle("Completions")
            .inlineNavigationTitle()
            .toolbar { Button("Done") { dismiss() } }
        }
    }
}

struct StreaksDetailView: View {
    @Environment(\.dismiss) private var dismiss
    let habits: [Habit]
    
    var body: some View {
        NavigationStack {
            List(habits.sorted { ($0.streak?.currentStreak ?? 0) > ($1.streak?.currentStreak ?? 0) }) { habit in
                if let streak = habit.streak {
                    VStack(alignment: .leading, spacing: 8) {
                        Label(habit.name, systemImage: "circle.fill").foregroundStyle(habit.color.color).font(.headline)
                        HStack {
                            Label("\(streak.currentStreak) current", systemImage: "flame.fill").foregroundStyle(.orange)
                            Spacer()
                            Label("\(streak.longestStreak) longest", systemImage: "trophy.fill").foregroundStyle(.yellow)
                        }
                        .font(.caption)
                    }
                }
            }
            .navigationTitle("Streaks")
            .inlineNavigationTitle()
            .toolbar { Button("Done") { dismiss() } }
        }
    }
}

struct HabitsDetailView: View {
    @Environment(\.dismiss) private var dismiss
    let habits: [Habit]
    
    var body: some View {
        NavigationStack {
            List(habits) { habit in
                VStack(alignment: .leading, spacing: 8) {
                    Label(habit.name, systemImage: habit.iconName ?? "circle.fill")
                        .foregroundStyle(habit.color.color)
                        .font(.headline)
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
        }
    }
}

struct StatCard: View {
    let title: String, value: String, icon: String, color: Color
    
    var body: some View {
        HStack {
            Image(systemName: icon).foregroundStyle(color).font(.title2).frame(width: 40)
            VStack(alignment: .leading, spacing: 4) {
                Text(title).font(.subheadline).foregroundStyle(.secondary)
                Text(value).font(.title2).bold()
            }
            Spacer()
            Image(systemName: "chevron.right").foregroundStyle(.secondary).font(.caption)
        }
        .padding()
        .background(Color.systemGray6)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct HabitStatRow: View {
    let habit: Habit
    let dateRange: (start: Date, end: Date)
    
    private var count: Int {
        habit.entries.filter { $0.isCompleted && $0.date >= dateRange.start && $0.date <= dateRange.end }.count
    }
    
    var body: some View {
        HStack {
            Circle().fill(habit.color.color).frame(width: 12, height: 12)
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
            Circle().fill(habit.color.color).frame(width: 12, height: 12)
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
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(iconColor)
                Text(title)
                    .font(.headline)
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 12)
            
            if isEmpty {
                emptyContent()
            } else {
                VStack(spacing: 0) {
                    content()
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.systemGray6)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal)
    }
}

struct StatsEmptyState: View {
    let icon: String
    let title: String
    let message: String
    
    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 28))
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
        .padding(.vertical, 24)
        .padding(.horizontal, 20)
    }
}

#Preview {
    StatisticsView()
        .modelContainer(for: Habit.self, inMemory: true)
}
