import Foundation
import SwiftData

@available(iOS 17.0, macOS 14.0, *)
enum AppConfig {
    static var schema: Schema {
        Schema([Habit.self, HabitEntry.self, Streak.self])
    }

    /// Same store URL for both local-only and CloudKit containers so switching to CloudKit
    /// reuses the same store and sync can populate it (or it’s already the synced store).
    nonisolated static func habitStoreURL() -> URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let name = Bundle.main.bundleIdentifier ?? "HabitTracker"
        let dir = base.appending(path: name, directoryHint: .isDirectory)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appending(path: "habits.store", directoryHint: .notDirectory)
    }
    
    /// Call from a background context when possible to avoid main-thread I/O. Safe to call from any isolation context (Swift 6).
    /// When useCloudKit is true, enable iCloud + CloudKit capability in Xcode and pass true when the user is signed in (for sync).
    nonisolated static func createModelContainer(useCloudKit: Bool = false) throws -> ModelContainer {
        let schema = Schema([Habit.self, HabitEntry.self, Streak.self])
        let storeURL = habitStoreURL()
        let config = ModelConfiguration(
            "Default",
            schema: schema,
            url: storeURL,
            allowsSave: true,
            cloudKitDatabase: useCloudKit ? .automatic : .none
        )
        return try ModelContainer(for: schema, configurations: config)
    }
}

// MARK: - App Store / Support URLs (Info.plist: PrivacyPolicyURL, SupportURL)

enum AppLinks {
    /// Read from Info.plist PrivacyPolicyURL. Canonical live policy: naga-siddhartha.github.io/Habit-GrabIt/privacy.html (GitHub Pages from repo naga-siddhartha/Habit-GrabIt).
    static var privacyPolicyURL: URL? {
        guard let string = Bundle.main.object(forInfoDictionaryKey: "PrivacyPolicyURL") as? String,
              !string.isEmpty else { return nil }
        return URL(string: string)
    }
    
    static var supportURL: URL? {
        guard let string = Bundle.main.object(forInfoDictionaryKey: "SupportURL") as? String,
              !string.isEmpty else { return nil }
        return URL(string: string)
    }
}
