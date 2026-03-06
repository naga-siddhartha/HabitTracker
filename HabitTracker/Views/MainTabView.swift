import SwiftUI
import SwiftData

#if !os(watchOS)
// MARK: - Main Tab View

struct MainTabView: View {
    @AppStorage("appearanceMode") private var appearanceMode = AppearanceMode.system
    @State private var selectedTab = 0
    @State private var isPresentingTemplates = false
    @State private var isResetting = false

    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView(onPresentTemplates: { isPresentingTemplates = true })
                .sheet(isPresented: $isPresentingTemplates) {
                    HabitTemplatesView(onDismissTemplates: { isPresentingTemplates = false })
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

            SettingsView(onRequestReset: performReset)
                .tag(3)
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
        }
        .preferredColorScheme(appearanceMode.preferredColorScheme)
        .fullScreenCover(isPresented: $isResetting) {
            ZStack {
                Color.appGroupedBackground.ignoresSafeArea()
                VStack(spacing: 16) {
                    ProgressView()
                        .scaleEffect(1.2)
                    Text("Resetting…")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private func performReset() {
        isResetting = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            NotificationService.shared.cancelAllNotifications()
            HabitStore.shared.deleteAllHabits()
            // Switch to Home first so when the cover dismisses, we're not on Settings/Stats (avoids re-rendering with stale @Query).
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                selectedTab = 0
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.4) {
                isResetting = false
            }
        }
    }
}
#endif
