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

    static func recreateContainerWithCloudKitStarted() {
        log.info("recreateContainerWithCloudKit() called (e.g. sign-in or Sync now)")
    }

    static func recreateContainerWithCloudKitSuccess() {
        log.info("recreateContainerWithCloudKit() succeeded – container now uses CloudKit")
    }

    static func recreateContainerWithCloudKitFailed(_ error: Error) {
        log.error("recreateContainerWithCloudKit() failed: \(error.localizedDescription)")
    }

    static func syncNowTapped() {
        log.info("Sync now tapped – triggering container recreate with CloudKit")
    }
}
