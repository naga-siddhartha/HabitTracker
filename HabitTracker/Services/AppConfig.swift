import Foundation
import SwiftData

@available(iOS 17.0, macOS 14.0, *)
enum AppConfig {
    static var schema: Schema {
        Schema([Habit.self, HabitEntry.self, Streak.self])
    }
    
    static func createModelContainer() throws -> ModelContainer {
        // Use .none for local-only storage. For iCloud sync: add iCloud + CloudKit capability
        // in Xcode, then use cloudKitDatabase: .automatic (and remove isStoredInMemoryOnly or keep false).
        let config = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            cloudKitDatabase: .none
        )
        return try ModelContainer(for: schema, configurations: config)
    }
}

// MARK: - App Store / Support URLs (Info.plist: PrivacyPolicyURL, SupportURL)

enum AppLinks {
    /// Read from Info.plist keys PrivacyPolicyURL and SupportURL. Replace placeholder values with your real URLs before App Store submission.
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
