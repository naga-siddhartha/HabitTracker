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
        .modifier(ResettingOverlayModifier(isPresented: $isResetting))
    }

    private func performReset() {
        isResetting = true
        Task { @MainActor in
            NotificationService.shared.cancelAllNotifications()
            HabitStore.shared.deleteAllHabitsImmediate()
            selectedTab = 0
            isResetting = false
        }
    }
}

// MARK: - Resetting overlay (fullScreenCover on iOS, sheet on macOS)

private struct ResettingOverlayModifier: ViewModifier {
    @Binding var isPresented: Bool

    private var resettingContent: some View {
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

    func body(content: Content) -> some View {
        #if os(iOS)
        content
            .fullScreenCover(isPresented: $isPresented) {
                resettingContent
            }
        #else
        content
            .sheet(isPresented: $isPresented) {
                resettingContent
            }
        #endif
    }
}
#endif
