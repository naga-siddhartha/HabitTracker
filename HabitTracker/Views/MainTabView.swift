import SwiftUI
import SwiftData

// MARK: - Main Tab View

struct MainTabView: View {
    @AppStorage("appearanceMode") private var appearanceMode = AppearanceMode.system
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @State private var selectedTab = 0
    @State private var isPresentingTemplates = false
    @State private var isResetting = false
    @State private var accountMenuState = AccountMenuState()
    private var milestones = MilestoneCenter.shared
    
    private var showOnboarding: Binding<Bool> {
        Binding(
            get: { !hasCompletedOnboarding },
            set: {
                if !$0 && !hasCompletedOnboarding {
                    hasCompletedOnboarding = true
                    Analytics.track(.onboardingCompleted)
                }
            }
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
        .tint(Color.brandPurple)
        .environment(accountMenuState)
        #if DEBUG
        .onAppear {
            let args = CommandLine.arguments
            // Tab switching works with or without full demo mode (used for App Review screenshots).
            if let idx = args.firstIndex(of: "-demoTab"),
               idx + 1 < args.count,
               let tab = Int(args[idx + 1]) {
                selectedTab = tab
            }
            guard MarketingDemoSeeder.isActive else { return }
            if args.contains("-demoTemplates") {
                isPresentingTemplates = true
            }
        }
        #if os(iOS)
        .fullScreenCover(isPresented: .constant(
            MarketingDemoSeeder.isActive && CommandLine.arguments.contains("-demoWidgetPreview")
        )) {
            WidgetPreviewScreen()
        }
        #endif
        #endif
        #if os(macOS)
        .withAccountToolbar(accountMenuState: accountMenuState)
        #endif
        .overlay(alignment: .top) {
            if let event = milestones.current {
                MilestoneBanner(event: event) {
                    withAnimation(.smooth) { milestones.current = nil }
                }
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .animation(.spring(duration: 0.45, bounce: 0.3), value: milestones.current)
        .preferredColorScheme(appearanceMode.preferredColorScheme)
        .modifier(ResettingOverlayModifier(isPresented: $isResetting))
        .sheet(isPresented: showOnboarding, onDismiss: { isPresentingTemplates = true }) {
            OnboardingView()
                .presentationDetents([.medium])
                .interactiveDismissDisabled()
        }
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
