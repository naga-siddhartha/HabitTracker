import SwiftUI

struct AchievementsView: View {
    @StateObject private var habitService = HabitService.shared
    @StateObject private var streakService = StreakService.shared
    @State private var achievements: [Achievement] = []
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Summary
                    VStack(spacing: 8) {
                        Text("\(unlockedCount)/\(achievements.count)")
                            .font(.largeTitle)
                            .bold()
                        
                        Text("Achievements Unlocked")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    
                    // Achievements grid
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
                        ForEach(achievements) { achievement in
                            AchievementCard(achievement: achievement)
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Achievements")
            .onAppear {
                loadAchievements()
            }
        }
    }
    
    private var unlockedCount: Int {
        achievements.filter { $0.isUnlocked }.count
    }
    
    private func loadAchievements() {
        // Generate achievements based on current data
        var newAchievements: [Achievement] = []
        
        let habits = habitService.getActiveHabits()
        let streaks = streakService.streaks
        
        // First habit achievement
        if habits.count >= 1 {
            newAchievements.append(Achievement(
                name: "Getting Started",
                description: "Create your first habit",
                iconName: "star.fill",
                criteria: .habitCount(count: 1),
                isUnlocked: true,
                progress: 1.0
            ))
        }
        
        // Streak achievements
        for streak in streaks {
            if streak.currentStreak >= 7 {
                newAchievements.append(Achievement(
                    name: "Week Warrior",
                    description: "Maintain a 7-day streak",
                    iconName: "flame.fill",
                    criteria: .streak(days: 7),
                    isUnlocked: streak.currentStreak >= 7,
                    progress: min(1.0, Double(streak.currentStreak) / 7.0)
                ))
            }
            
            if streak.currentStreak >= 30 {
                newAchievements.append(Achievement(
                    name: "Monthly Master",
                    description: "Maintain a 30-day streak",
                    iconName: "calendar",
                    criteria: .streak(days: 30),
                    isUnlocked: streak.currentStreak >= 30,
                    progress: min(1.0, Double(streak.currentStreak) / 30.0)
                ))
            }
        }
        
        achievements = newAchievements
    }
}

struct AchievementCard: View {
    let achievement: Achievement
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: achievement.iconName)
                .font(.system(size: 40))
                .foregroundColor(achievement.isUnlocked ? .yellow : .gray)
                .opacity(achievement.isUnlocked ? 1.0 : 0.5)
            
            Text(achievement.name)
                .font(.headline)
                .multilineTextAlignment(.center)
            
            Text(achievement.description)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            if !achievement.isUnlocked {
                ProgressView(value: achievement.progress)
                    .progressViewStyle(.linear)
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(achievement.isUnlocked ? Color.yellow.opacity(0.1) : Color(UIColor.systemGray6))
        .cornerRadius(12)
    }
}

#Preview {
    AchievementsView()
}
