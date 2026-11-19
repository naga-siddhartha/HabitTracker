import CloudKit
import Foundation

/// Deletes everything this app has synced to the user's private iCloud database.
/// SwiftData's CloudKit mirroring keeps all records in one zone, so deleting that zone removes
/// every synced habit, entry and streak in one request.
enum CloudDataEraser {
    static let containerIdentifier = "iCloud.com.nagasiddharthadonepudi.HabitTracker"
    static let mirroringZone = CKRecordZone.ID(zoneName: "com.apple.coredata.cloudkit.zone", ownerName: CKCurrentUserDefaultName)

    static func deleteSyncedData() async throws {
        let database = CKContainer(identifier: containerIdentifier).privateCloudDatabase
        do {
            _ = try await database.deleteRecordZone(withID: mirroringZone)
        } catch let error as CKError where error.code == .zoneNotFound || error.code == .unknownItem {
            // Nothing was ever synced, so there is nothing to delete.
        }
    }
}
