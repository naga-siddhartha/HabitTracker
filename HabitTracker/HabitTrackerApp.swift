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
    let store = HabitStore.shared

    init() {
        store.updateAllStreaks()
        store.writeWidgetData()
        #if os(iOS)
        configureTabBarAppearance()
        // Set test device ID immediately so first ad request uses it (banner can load before async below runs).
        MobileAds.shared.requestConfiguration.testDeviceIdentifiers = [
            "7898b85d170daffccea1430f55291c02",
            "eca025c65f76a343b5651fde452346bd", // Mac (simulator/Catalyst)
        ]
        // Defer AdMob start off the launch path to avoid "Launch Background Task for Coalescing" expiration warning.
        DispatchQueue.main.async {
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


#if os(watchOS)
struct WatchMainView: View {
    var body: some View {
        Text("Habits")
    }
}
#endif

