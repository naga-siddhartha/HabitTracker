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
    /// Only called on sign-in. We must avoid opening the same store twice with CloudKit (causes "another instance actively syncing"). So we switch to an in-memory container first so the old one can tear down, then create the new CloudKit-backed container.
    func recreateContainerWithCloudKit() {
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
                } catch {
                    SyncLogger.recreateContainerWithCloudKitFailed(error)
                    self.currentContainer = (try? AppConfig.createModelContainer(useCloudKit: false)) ?? fallback
                }
            }
        }
    }
}

extension Notification.Name {
    static let userDidSignIn = Notification.Name("userDidSignIn")
}
