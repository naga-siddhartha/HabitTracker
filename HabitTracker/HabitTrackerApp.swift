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
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            TodayView()
                .tag(0)
                .tabItem {
                    Label("Today", systemImage: "circle.inset.filled")
                }
            
            CalendarContainerView()
                .tag(1)
                .tabItem {
                    Label("Calendar", systemImage: "calendar")
                }
            
            StatisticsView()
                .tag(2)
                .tabItem {
                    Label("Stats", systemImage: "chart.bar")
                }
            
            SettingsView()
                .tag(3)
                .tabItem {
                    Label("Settings", systemImage: "gearshape")
                }
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
            VStack(spacing: 0) {
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
            .navigationTitle("Calendar")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
#endif
