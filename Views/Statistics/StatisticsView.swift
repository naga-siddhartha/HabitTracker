import SwiftUI

struct StatisticsView: View {
    @StateObject private var habitService = HabitService.shared
    @StateObject private var streakService = StreakService.shared
    @State private var selectedTimeframe: Timeframe = .allTime
    
    enum Timeframe: String, CaseIterable {
        case week = "Week"
        case month = "Month"
        case year = "Year"
        case allTime = "All Time"
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Timeframe selector
                    Picker("Timeframe", selection: $selectedTimeframe) {
                        ForEach(Timeframe.allCases, id: \.self) { timeframe in
                            Text(timeframe.rawValue).tag(timeframe)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding()
                    
                    // Overall stats
                    VStack(spacing: 16) {
                        StatCard(
                            title: "Total Habits",
                            value: "\(habitService.getActiveHabits().count)",
                            icon: "list.bullet",
                            color: .blue
                        )
                        
                        StatCard(
                            title: "Total Completions",
                            value: "\(totalCompletions)",
                            icon: "checkmark.circle.fill",
                            color: .green
                        )
                        
                        StatCard(
                            title: "Current Streaks",
                            value: "\(activeStreaks)",
                            icon: "flame.fill",
                            color: .orange
                        )
                    }
                    .padding(.horizontal)
                    
                    // Top habits
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Top Performing Habits")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        ForEach(topHabits.prefix(5), id: \.id) { habit in
                            HabitStatRow(habit: habit)
                        }
                    }
                    .padding(.vertical)
                    
                    // Streaks leaderboard
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Longest Streaks")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        ForEach(streakLeaderboard.prefix(5), id: \.id) { streak in
                            if let habit = habitService.getHabit(id: streak.habitId) {
                                StreakRow(habit: habit, streak: streak)
                            }
                        }
                    }
                    .padding(.vertical)
                }
            }
            .navigationTitle("Statistics")
        }
    }
    
    private var totalCompletions: Int {
        let habits = habitService.getActiveHabits()
        let dateRange = getDateRange()
        
        return habits.reduce(0) { total, habit in
            total + habitService.getEntries(for: habit.id, from: dateRange.start, to: dateRange.end).count
        }
    }
    
    private var activeStreaks: Int {
        streakService.streaks.filter { $0.currentStreak > 0 }.count
    }
    
    private var topHabits: [Habit] {
        let habits = habitService.getActiveHabits()
        let dateRange = getDateRange()
        
        return habits.sorted { habit1, habit2 in
            let count1 = habitService.getEntries(for: habit1.id, from: dateRange.start, to: dateRange.end).count
            let count2 = habitService.getEntries(for: habit2.id, from: dateRange.start, to: dateRange.end).count
            return count1 > count2
        }
    }
    
    private var streakLeaderboard: [Streak] {
        streakService.streaks.sorted { $0.longestStreak > $1.longestStreak }
    }
    
    private func getDateRange() -> (start: Date, end: Date) {
        let calendar = Calendar.current
        let now = Date()
        
        switch selectedTimeframe {
        case .week:
            return (now.startOfWeek ?? now, now.endOfWeek ?? now)
        case .month:
            return (now.startOfMonth ?? now, now.endOfMonth ?? now)
        case .year:
            return (now.startOfYear ?? now, now.endOfYear ?? now)
        case .allTime:
            return (Date.distantPast, Date())
        }
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(color)
                .font(.title2)
                .frame(width: 40)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Text(value)
                    .font(.title2)
                    .bold()
            }
            
            Spacer()
        }
        .padding()
        .background(Color(UIColor.systemGray6))
        .cornerRadius(12)
    }
}

struct HabitStatRow: View {
    let habit: Habit
    @StateObject private var habitService = HabitService.shared
    
    private var completionCount: Int {
        habitService.getEntries(for: habit.id).count
    }
    
    var body: some View {
        HStack {
            Circle()
                .fill(habit.color.color)
                .frame(width: 12, height: 12)
            
            Text(habit.name)
                .font(.subheadline)
            
            Spacer()
            
            Text("\(completionCount) completions")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal)
    }
}

struct StreakRow: View {
    let habit: Habit
    let streak: Streak
    
    var body: some View {
        HStack {
            Circle()
                .fill(habit.color.color)
                .frame(width: 12, height: 12)
            
            Text(habit.name)
                .font(.subheadline)
            
            Spacer()
            
            HStack(spacing: 4) {
                Image(systemName: "flame.fill")
                    .foregroundColor(.orange)
                    .font(.caption)
                Text("\(streak.longestStreak) days")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal)
    }
}

#Preview {
    StatisticsView()
}
