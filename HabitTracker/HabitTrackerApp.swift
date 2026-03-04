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


#if os(watchOS)
struct WatchMainView: View {
    var body: some View {
        Text("Habits")
    }
}
#endif

