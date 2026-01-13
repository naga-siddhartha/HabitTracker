import SwiftUI

@main
struct HabitTrackerApp: App {
    @StateObject private var habitService = HabitService.shared
    @StateObject private var streakService = StreakService.shared
    @StateObject private var notificationService = NotificationService.shared
    
    init() {
        // Initialize services
        _ = HabitService.shared
        _ = StreakService.shared
        _ = NotificationService.shared
        
        // Update all streaks on app launch
        StreakService.shared.updateAllStreaks()
    }
    
    var body: some Scene {
        WindowGroup {
            MainTabView()
                .environmentObject(habitService)
                .environmentObject(streakService)
                .environmentObject(notificationService)
        }
    }
}

struct MainTabView: View {
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            TodayView()
                .tabItem {
                    Label("Today", systemImage: "calendar")
                }
                .tag(0)
            
            HabitListView()
                .tabItem {
                    Label("Habits", systemImage: "list.bullet")
                }
                .tag(1)
            
            CalendarContainerView()
                .tabItem {
                    Label("Calendar", systemImage: "calendar.badge.clock")
                }
                .tag(2)
            
            StatisticsView()
                .tabItem {
                    Label("Statistics", systemImage: "chart.bar")
                }
                .tag(3)
        }
    }
}

struct CalendarContainerView: View {
    @State private var selectedView: CalendarViewModel.CalendarViewType = .monthly
    
    var body: some View {
        NavigationView {
            VStack {
                Picker("View", selection: $selectedView) {
                    Text("Daily").tag(CalendarViewModel.CalendarViewType.daily)
                    Text("Weekly").tag(CalendarViewModel.CalendarViewType.weekly)
                    Text("Monthly").tag(CalendarViewModel.CalendarViewType.monthly)
                    Text("Yearly").tag(CalendarViewModel.CalendarViewType.yearly)
                }
                .pickerStyle(.segmented)
                .padding()
                
                switch selectedView {
                case .daily:
                    DailyView()
                case .weekly:
                    WeeklyView()
                case .monthly:
                    MonthlyView()
                case .yearly:
                    YearlyView()
                }
            }
        }
    }
}
