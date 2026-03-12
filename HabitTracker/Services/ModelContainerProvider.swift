import Combine
import Foundation
import SwiftData

/// Provides the app's ModelContainer. Can be recreated with CloudKit when the user signs in
/// so sync works even if the app was launched before sign-in.
@available(iOS 17.0, macOS 14.0, *)
final class ModelContainerProvider: ObservableObject {
    static let shared: ModelContainerProvider = {
        let p = ModelContainerProvider()
        p.observeSignIn()
        return p
    }()

    @Published private(set) var currentContainer: ModelContainer
    /// True while "Sync now" is reconnecting the container so CloudKit can merge remote changes. UI can show "Syncing…".
    @Published private(set) var isSyncing = false
    private var isRecreating = false

    private init() {
        let useCloudKit = KeychainHelper.loadUserId() != nil
        do {
            currentContainer = try AppConfig.createModelContainer(useCloudKit: useCloudKit)
            SyncLogger.containerCreated(useCloudKit: useCloudKit, storeURL: AppConfig.habitStoreURL(), success: true)
        } catch {
            SyncLogger.containerCreated(useCloudKit: useCloudKit, storeURL: AppConfig.habitStoreURL(), success: false, error: error)
            if useCloudKit {
                currentContainer = (try? AppConfig.createModelContainer(useCloudKit: false))
                    ?? Self.fallbackContainer()
            } else {
                currentContainer = Self.fallbackContainer()
            }
        }
    }

    private static func fallbackContainer() -> ModelContainer {
        (try? ModelContainer(for: AppConfig.schema, configurations: ModelConfiguration(isStoredInMemoryOnly: true)))
            ?? (try! ModelContainer(for: AppConfig.schema, configurations: ModelConfiguration(isStoredInMemoryOnly: true)))
    }

    private func observeSignIn() {
        NotificationCenter.default.addObserver(
            forName: .userDidSignIn,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.recreateContainerWithCloudKit()
        }
    }

    /// Recreate the container with CloudKit enabled so sync can pull from iCloud.
    /// Called on sign-in and when the user taps "Sync now". We must avoid opening the same store twice with CloudKit (causes "another instance actively syncing"). So we switch to an in-memory container first so the old one can tear down, then create the new CloudKit-backed container.
    /// - Parameter completion: Optional callback on main when done (success or failure). Use from "Sync now" to e.g. reload widgets.
    func recreateContainerWithCloudKit(completion: (() -> Void)? = nil) {
        guard !isRecreating else {
            completion?()
            return
        }
        isRecreating = true
        isSyncing = true
        SyncLogger.recreateContainerWithCloudKitStarted()
        let fallback = Self.fallbackContainer()
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.currentContainer = fallback
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
                guard let self else { return }
                do {
                    let newContainer = try AppConfig.createModelContainer(useCloudKit: true)
                    self.currentContainer = newContainer
                    SyncLogger.recreateContainerWithCloudKitSuccess()
                    // Give CloudKit time to fetch and merge remote changes before we refresh UI and widgets.
                    let finish: () -> Void = {
                        self.isRecreating = false
                        self.isSyncing = false
                        completion?()
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.2, execute: finish)
                } catch {
                    SyncLogger.recreateContainerWithCloudKitFailed(error)
                    self.currentContainer = (try? AppConfig.createModelContainer(useCloudKit: false)) ?? fallback
                    self.isRecreating = false
                    self.isSyncing = false
                    completion?()
                }
            }
        }
    }
}

extension Notification.Name {
    static let userDidSignIn = Notification.Name("userDidSignIn")
}
