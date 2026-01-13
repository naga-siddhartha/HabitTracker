import SwiftUI
import SwiftData

@main
struct HabitTrackerApp: App {
    let store = HabitStore.shared
    
    init() {
        store.updateAllStreaks()
    }
    
    var body: some Scene {
        WindowGroup {
            #if os(watchOS)
            WatchMainView()
            #else
            MainTabView()
            #endif
        }
        .modelContainer(store.modelContainer)
        
        #if os(macOS)
        Settings {
            SettingsView()
        }
        #endif
    }
}

#if !os(watchOS)
struct MainTabView: View {
    var body: some View {
        TabView {
            #if os(iOS)
            Tab("Today", systemImage: "calendar") {
                TodayView()
            }
            Tab("Habits", systemImage: "list.bullet") {
                HabitListView()
            }
            Tab("Calendar", systemImage: "calendar.badge.clock") {
                CalendarContainerView()
            }
            Tab("Statistics", systemImage: "chart.bar") {
                StatisticsView()
            }
            Tab("Settings", systemImage: "gear") {
                SettingsView()
            }
            #else
            TodayView().tabItem { Label("Today", systemImage: "calendar") }
            HabitListView().tabItem { Label("Habits", systemImage: "list.bullet") }
            CalendarContainerView().tabItem { Label("Calendar", systemImage: "calendar.badge.clock") }
            StatisticsView().tabItem { Label("Statistics", systemImage: "chart.bar") }
            #endif
        }
    }
}

struct CalendarContainerView: View {
    @State private var selectedView: CalendarViewType = .monthly
    
    enum CalendarViewType: String, CaseIterable {
        case daily = "Daily", weekly = "Weekly", monthly = "Monthly", yearly = "Yearly"
    }
    
    var body: some View {
        NavigationStack {
            VStack {
                Picker("View", selection: $selectedView) {
                    ForEach(CalendarViewType.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                }
                .pickerStyle(.segmented)
                .padding()
                
                switch selectedView {
                case .daily: DailyView()
                case .weekly: WeeklyView()
                case .monthly: MonthlyView()
                case .yearly: YearlyView()
                }
            }
        }
    }
}
#endif
