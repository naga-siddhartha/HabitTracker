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
    @State private var isPresentingAddHabit = false
    
    var body: some View {
        TabView(selection: $selectedTab) {
            ZStack {
                HomeView()
                
                // Floating Add Button
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button {
                            isPresentingAddHabit = true
                        } label: {
                            Image(systemName: "plus")
                                .font(.system(size: 22, weight: .bold))
                                .foregroundStyle(.white)
                                .padding(20)
                                .background(Circle().fill(Color.accentColor))
                                .shadow(radius: 4)
                        }
                        .accessibilityLabel("Add Habit")
                        .buttonStyle(.plain)
                        .padding(.trailing, 20)
                        .padding(.bottom, 24)
                    }
                }
            }
            .sheet(isPresented: $isPresentingAddHabit) {
                AddEditHabitView()
            }
            .tag(0)
            .tabItem {
                Label("Home", systemImage: "house.fill")
            }
            
            CalendarContainerView()
                .tag(1)
                .tabItem {
                    Label("Calendar", systemImage: "calendar")
                }
            
            StatisticsView()
                .tag(2)
                .tabItem {
                    Label("Stats", systemImage: "chart.bar.fill")
                }
            
            SettingsView()
                .tag(3)
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
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
                .labelsHidden()
                .padding()
                
                switch selectedView {
                case .daily: DailyView()
                case .weekly: WeeklyView()
                case .monthly: MonthlyView()
                case .yearly: YearlyView()
                }
            }
            .navigationTitle("Calendar")
            #if os(iOS)
            .inlineNavigationTitle()
            #endif
        }
    }
}
#endif

