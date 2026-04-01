import SwiftUI
import SwiftData

// MARK: - Main Tab View

struct MainTabView: View {
    @AppStorage("appearanceMode") private var appearanceMode = AppearanceMode.system
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @State private var selectedTab = 0
    @State private var isPresentingTemplates = false
    @State private var isResetting = false
    @StateObject private var accountMenuState = AccountMenuState()
    
    private var showOnboarding: Binding<Bool> {
        Binding(
            get: { !hasCompletedOnboarding },
            set: { if !$0 { hasCompletedOnboarding = true } }
        )
    }

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
            .accessibilityHint("Today's habits")

            CalendarContainerView()
                .tag(1)
                .tabItem {
                    Label("Calendar", systemImage: "calendar")
                }
            .accessibilityHint("View and edit habits by date")

            StatisticsView()
                .tag(2)
                .tabItem {
                    Label("Stats", systemImage: "chart.bar.fill")
                }
            .accessibilityHint("Habit statistics and streaks")

            SettingsView(onRequestReset: performReset)
                .tag(3)
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
            .accessibilityHint("Notifications, appearance, and data")
        }
        .environmentObject(accountMenuState)
        #if os(macOS)
        .withAccountToolbar(accountMenuState: accountMenuState)
        #endif
        .preferredColorScheme(appearanceMode.preferredColorScheme)
        .modifier(ResettingOverlayModifier(isPresented: $isResetting))
        .modifier(OnboardingOverlayModifier(showOnboarding: showOnboarding) {
            OnboardingView(onGetStarted: {
                isPresentingTemplates = true
            })
        })
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

// MARK: - Onboarding overlay (translucent over Home on iOS, sheet on macOS)

private struct OnboardingOverlayModifier<OverlayContent: View>: ViewModifier {
    @Binding var showOnboarding: Bool
    @ViewBuilder let overlayContent: () -> OverlayContent

    func body(content: Content) -> some View {
        #if os(iOS)
        content
            .overlay {
                if showOnboarding {
                    overlayContent()
                        .transition(.opacity)
                }
            }
            .animation(.easeInOut(duration: 0.25), value: showOnboarding)
        #else
        content
            .sheet(isPresented: $showOnboarding) {
                overlayContent()
            }
        #endif
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
