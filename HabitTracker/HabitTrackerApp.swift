import SwiftUI
import SwiftData

#if canImport(UIKit)
import UIKit
#endif

@main
struct HabitTrackerApp: App {
    let store = HabitStore.shared

    init() {
        store.updateAllStreaks()
        #if os(iOS)
        configureTabBarAppearance()
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

