import SwiftUI
import SwiftData

#if canImport(UIKit)
import UIKit
#endif
#if os(iOS)
import GoogleMobileAds
#endif

@main
struct HabitTrackerApp: App {
    @State private var containerProvider = ModelContainerProvider.shared
    let store = HabitStore.shared
    @State private var showingStoreError = false
    @Environment(\.scenePhase) private var scenePhase

    init() {
        Analytics.start()
        SyncMonitor.shared.start()
        PurchaseManager.shared.start()
        #if os(iOS)
        configureTabBarAppearance()
        // Buyers of Remove Ads never load the ads SDK at all (faster launch, no ad network traffic).
        if !PurchaseManager.shared.isAdFree {
            #if DEBUG
            MobileAds.shared.requestConfiguration.testDeviceIdentifiers = [
                "7898b85d170daffccea1430f55291c02",
                "eca025c65f76a343b5651fde452346bd", // Mac (simulator/Catalyst)
            ]
            #endif
            // Start SDK as early as possible so banner can load after a short delay (see AdMobBannerView).
            MobileAds.shared.start(completionHandler: { (_: InitializationStatus) in })
        }
        #endif
    }

    #if os(iOS)
    private func configureTabBarAppearance() {
        let tabBar = UITabBar.appearance()
        tabBar.unselectedItemTintColor = UIColor.tertiaryLabel
        tabBar.tintColor = UIColor(red: 0.35, green: 0.51, blue: 0.88, alpha: 1)
    }
    #endif
    
    var body: some Scene {
        WindowGroup {
            MainTabView()
                .environment(containerProvider)
                .onAppear {
                    showingStoreError = containerProvider.storeLoadError != nil
                    Analytics.trackLaunchTimeOnce()
                    // Let the first frame render, then do housekeeping.
                    Task { @MainActor in
                        await Task.yield()
                        store.performLaunchMaintenance()
                    }
                }
                .onChange(of: scenePhase, initial: true) { _, phase in
                    guard phase == .active else { return }
                    Analytics.sendDailySummaryIfNeeded(
                        habits: store.fetchHabits(),
                        cloudSyncOn: containerProvider.isCloudSyncEnabled
                    )
                }
                .alert("Your habits couldn't be opened", isPresented: $showingStoreError) {
                    Button("OK", role: .cancel) {}
                } message: {
                    Text("Your data hasn't been deleted, but changes you make now won't be saved. Please quit and reopen the app. If this keeps happening, contact support.\n\n\(containerProvider.storeLoadError ?? "")")
                }
        }
        .modelContainer(containerProvider.currentContainer)
        
        #if os(macOS)
        Settings {
            SettingsView()
        }
        #endif
    }
}
