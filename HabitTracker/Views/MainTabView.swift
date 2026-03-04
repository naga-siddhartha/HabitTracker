import SwiftUI
import SwiftData

#if !os(watchOS)
// MARK: - Main Tab View

struct MainTabView: View {
    @AppStorage("appearanceMode") private var appearanceMode = AppearanceMode.system
    @State private var selectedTab = 0
    @State private var isPresentingTemplates = false

    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView(onPresentTemplates: { isPresentingTemplates = true })
                .sheet(isPresented: $isPresentingTemplates) {
                    HabitTemplatesView()
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
        .preferredColorScheme(appearanceMode.preferredColorScheme)
    }
}
#endif
