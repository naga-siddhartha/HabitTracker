import Foundation
import SwiftData

enum AppConfig {
    static let cloudKitContainerID = "iCloud.com.habittracker.app"
    static let appGroupID = "group.com.habittracker.app"
    
    static var schema: Schema {
        Schema([Habit.self, HabitEntry.self, Streak.self])
    }
    
    static func modelConfiguration(cloudKitEnabled: Bool = true) -> ModelConfiguration {
        ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            cloudKitDatabase: cloudKitEnabled ? .private(cloudKitContainerID) : .none
        )
    }
    
    static func createModelContainer(cloudKitEnabled: Bool = true) throws -> ModelContainer {
        try ModelContainer(for: schema, configurations: modelConfiguration(cloudKitEnabled: cloudKitEnabled))
    }
}
