import Foundation
import Observation
import SwiftData

/// Provides the app's ModelContainer and switches it between local-only and CloudKit-backed
/// when the user signs in or out.
///
/// CloudKit mirroring syncs on its own (on save, on launch and when iCloud pushes a change), so
/// there is no "sync now" container swap any more. The container is only replaced when the sync
/// mode actually changes, and it always opens the same store file, so data carries over.
@available(iOS 17.0, macOS 14.0, *)
@Observable
final class ModelContainerProvider {
    static let shared: ModelContainerProvider = {
        let p = ModelContainerProvider()
        p.observeAccountChanges()
        return p
    }()

    private(set) var currentContainer: ModelContainer
    /// True when the container is mirroring to CloudKit.
    private(set) var isCloudSyncEnabled: Bool
    /// Set when the user is signed in but the CloudKit container couldn't be created. Data is
    /// still saved locally; only sync is off.
    private(set) var cloudSetupError: String?
    /// Set when the on-disk store couldn't be opened at all and the app is running on a temporary
    /// in-memory store. Nothing saved in this state survives a relaunch, so the UI must say so.
    private(set) var storeLoadError: String?

    private init() {
        let wantsCloudKit = KeychainHelper.loadUserId() != nil
        let result = Self.makeContainer(useCloudKit: wantsCloudKit)
        currentContainer = result.container
        isCloudSyncEnabled = result.isCloudKit
        cloudSetupError = result.cloudError
        storeLoadError = result.storeError
    }

    private func observeAccountChanges() {
        NotificationCenter.default.addObserver(forName: .userDidSignIn, object: nil, queue: .main) { [weak self] _ in
            self?.setCloudSync(enabled: true)
        }
        NotificationCenter.default.addObserver(forName: .userDidSignOut, object: nil, queue: .main) { [weak self] _ in
            self?.setCloudSync(enabled: false)
        }
    }

    /// Switch between CloudKit-backed and local-only. No-op if already in the requested mode or if
    /// the app is on the temporary store (switching would hide the error, not fix it).
    func setCloudSync(enabled: Bool) {
        guard storeLoadError == nil, enabled != isCloudSyncEnabled else { return }
        HabitStore.shared.save()
        // Safe to open the new container directly: exactly one of the two has CloudKit on, so
        // the store is never mirrored by two containers at once.
        let result = Self.makeContainer(useCloudKit: enabled)
        guard result.storeError == nil else {
            // Keep using the working container rather than dropping to the temporary store.
            cloudSetupError = result.storeError
            return
        }
        currentContainer = result.container
        isCloudSyncEnabled = result.isCloudKit
        cloudSetupError = result.cloudError
    }

    // MARK: - Container creation

    private struct MakeResult {
        let container: ModelContainer
        let isCloudKit: Bool
        let cloudError: String?
        let storeError: String?
    }

    private static func makeContainer(useCloudKit: Bool) -> MakeResult {
        let url = AppConfig.habitStoreURL()
        var cloudError: String?
        if useCloudKit {
            do {
                let container = try AppConfig.createModelContainer(useCloudKit: true)
                SyncLogger.containerCreated(useCloudKit: true, storeURL: url, success: true)
                return MakeResult(container: container, isCloudKit: true, cloudError: nil, storeError: nil)
            } catch {
                SyncLogger.containerCreated(useCloudKit: true, storeURL: url, success: false, error: error)
                cloudError = error.localizedDescription
            }
        }
        do {
            let container = try AppConfig.createModelContainer(useCloudKit: false)
            SyncLogger.containerCreated(useCloudKit: false, storeURL: url, success: true)
            return MakeResult(container: container, isCloudKit: false, cloudError: cloudError, storeError: nil)
        } catch {
            SyncLogger.containerCreated(useCloudKit: false, storeURL: url, success: false, error: error)
            return MakeResult(container: temporaryContainer(), isCloudKit: false, cloudError: cloudError, storeError: error.localizedDescription)
        }
    }

    private static func temporaryContainer() -> ModelContainer {
        // An in-memory container with this schema only fails if the schema itself is invalid,
        // which would be a programming error caught in development.
        try! ModelContainer(for: AppConfig.schema, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
    }
}

extension Notification.Name {
    static let userDidSignIn = Notification.Name("userDidSignIn")
    static let userDidSignOut = Notification.Name("userDidSignOut")
}
