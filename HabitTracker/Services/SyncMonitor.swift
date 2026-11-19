import Combine
import CoreData
import Foundation

/// Reports real CloudKit sync activity. SwiftData mirrors through NSPersistentCloudKitContainer,
/// which posts an event for every setup, import and export, so the UI can show what is actually
/// happening instead of a fake "Sync now" spinner.
@available(iOS 17.0, macOS 14.0, *)
@MainActor
final class SyncMonitor: ObservableObject {
    static let shared = SyncMonitor()

    @Published private(set) var isSyncing = false
    @Published private(set) var lastSuccessfulSync: Date?
    @Published private(set) var lastError: String?

    private var inFlight = Set<UUID>()
    private var reportedErrorThisLaunch = false
    private var observer: NSObjectProtocol?
    private var pendingRemoteRefresh: Task<Void, Never>?

    private init() {
        observer = NotificationCenter.default.addObserver(
            forName: NSPersistentCloudKitContainer.eventChangedNotification,
            object: nil,
            queue: .main
        ) { [weak self] note in
            guard let event = note.userInfo?[NSPersistentCloudKitContainer.eventNotificationUserInfoKey]
                    as? NSPersistentCloudKitContainer.Event else { return }
            let id = event.identifier
            let type = event.type
            let ended = event.endDate
            let succeeded = event.succeeded
            let message = event.error?.localizedDescription
            MainActor.assumeIsolated {
                self?.handle(id: id, type: type, endDate: ended, succeeded: succeeded, error: message)
            }
        }
    }

    /// Call once at launch so events are captured from the start.
    func start() {}

    private func handle(id: UUID, type: NSPersistentCloudKitContainer.EventType, endDate: Date?, succeeded: Bool, error: String?) {
        guard let endDate else {
            inFlight.insert(id)
            isSyncing = true
            return
        }
        inFlight.remove(id)
        isSyncing = !inFlight.isEmpty
        if succeeded {
            lastSuccessfulSync = endDate
            lastError = nil
            if type == .import { scheduleRemoteRefresh() }
        } else if let error {
            lastError = error
            if !reportedErrorThisLaunch {
                reportedErrorThisLaunch = true
                Analytics.track(.syncError)
            }
        }
    }

    /// Imports arrive in bursts; refresh derived state once things settle.
    private func scheduleRemoteRefresh() {
        pendingRemoteRefresh?.cancel()
        pendingRemoteRefresh = Task { @MainActor in
            try? await Task.sleep(for: .seconds(1))
            guard !Task.isCancelled else { return }
            HabitStore.shared.handleRemoteChanges()
        }
    }
}

// MARK: - Status text

@available(iOS 17.0, macOS 14.0, *)
@MainActor
enum SyncStatus {
    /// One short line for Settings and the account menu.
    static func summary(monitor: SyncMonitor, provider: ModelContainerProvider) -> String {
        if provider.cloudSetupError != nil { return "Sync unavailable" }
        if !provider.isCloudSyncEnabled { return "Sync off" }
        if monitor.isSyncing { return "Syncing…" }
        if monitor.lastError != nil { return "Will retry shortly" }
        if let last = monitor.lastSuccessfulSync {
            return "Up to date · " + last.formatted(.relative(presentation: .named))
        }
        return "Waiting for iCloud"
    }
}
