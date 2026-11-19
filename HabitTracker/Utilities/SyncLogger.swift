import Foundation
import os.log

/// Use Console.app: filter by subsystem "HabitTracker.Sync" or process "HabitTracker" to see sync-related logs.
enum SyncLogger {
    private static let log = Logger(subsystem: "com.nagasiddharthadonepudi.HabitTracker", category: "Sync")

    static func containerCreated(useCloudKit: Bool, storeURL: URL, success: Bool, error: Error? = nil) {
        log.info("ModelContainer created useCloudKit=\(useCloudKit) storeURL=\(storeURL.path) success=\(success)")
        if let error {
            log.error("ModelContainer creation error: \(error.localizedDescription)")
        }
    }
}
