import Foundation
import SwiftData

enum AppConfig {
    // Update this to match your CloudKit container ID from Xcode capabilities
    static let cloudKitContainerID = "iCloud.com.habittracker"
    
    static var schema: Schema {
        Schema([Habit.self, HabitEntry.self, Streak.self])
    }
    
    static func createModelContainer() throws -> ModelContainer {
        let config = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            cloudKitDatabase: .automatic
        )
        return try ModelContainer(for: schema, configurations: config)
    }
}
