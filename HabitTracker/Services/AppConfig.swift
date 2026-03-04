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
