import Foundation
import UserNotifications
import WidgetKit
#if canImport(TelemetryDeck)
import TelemetryDeck
#endif

/// Anonymous usage metrics; KPI definitions are in docs/METRICS.md.
///
/// Never sends habit content, only bucketed counts and flags, as one daily summary plus a few
/// lifecycle events. No-op until the TelemetryDeck package and `TelemetryDeckAppID` are set up,
/// or when the user turns it off in Settings.
@MainActor
enum Analytics {
    static let enabledKey = "analyticsEnabled"
    private static let lastSummaryDayKey = "analytics.lastSummaryDay"
    private static var isStarted = false
    private static var launchStartedAt: Date?
    private static var launchTracked = false

    /// User setting. Defaults to on.
    static var isEnabled: Bool {
        UserDefaults.standard.object(forKey: enabledKey) as? Bool ?? true
    }

    /// True only when TelemetryDeck is linked and an app ID is set. Settings hides the toggle
    /// otherwise, so the app never offers a setting that does nothing.
    static var isAvailable: Bool {
        #if canImport(TelemetryDeck)
        let appID = Bundle.main.object(forInfoDictionaryKey: "TelemetryDeckAppID") as? String
        return !(appID ?? "").isEmpty
        #else
        return false
        #endif
    }

    /// Call from `App.init()`. Turning the setting off stops all signals immediately; turning it
    /// back on takes effect at the next launch.
    static func start() {
        if launchStartedAt == nil { launchStartedAt = Date() }
        guard isEnabled, !isStarted,
              let appID = Bundle.main.object(forInfoDictionaryKey: "TelemetryDeckAppID") as? String,
              !appID.isEmpty else { return }
        #if canImport(TelemetryDeck)
        TelemetryDeck.initialize(config: .init(appID: appID))
        isStarted = true
        #endif
    }

    // MARK: - Events

    enum Event {
        case onboardingCompleted
        case habitCreated(fromTemplate: Bool, hasReminder: Bool, isInterval: Bool, isWeekly: Bool)
        case habitDeleted
        case backupExported(format: String)
        case backupRestored
        case signedIn
        case accountDeleted
        case syncError
        case launchTime(seconds: TimeInterval)
        case removeAdsPurchased
        case removeAdsRestored
        case milestoneReached(days: Int)

        var name: String {
            switch self {
            case .onboardingCompleted: "Onboarding.completed"
            case .habitCreated: "Habit.created"
            case .habitDeleted: "Habit.deleted"
            case .backupExported: "Backup.exported"
            case .backupRestored: "Backup.restored"
            case .signedIn: "Account.signedIn"
            case .accountDeleted: "Account.deleted"
            case .syncError: "Sync.error"
            case .launchTime: "Performance.launch"
            case .removeAdsPurchased: "Purchase.removeAds"
            case .removeAdsRestored: "Purchase.restored"
            case .milestoneReached: "Streak.milestone"
            }
        }

        var parameters: [String: String] {
            switch self {
            case let .habitCreated(fromTemplate, hasReminder, isInterval, isWeekly):
                ["fromTemplate": "\(fromTemplate)", "hasReminder": "\(hasReminder)",
                 "isInterval": "\(isInterval)", "isWeekly": "\(isWeekly)"]
            case let .backupExported(format):
                ["format": format]
            case let .milestoneReached(days):
                ["days": "\(days)"]
            case let .launchTime(seconds):
                ["launchBucket": Analytics.launchBucket(seconds)]
            default:
                [:]
            }
        }
    }

    static func track(_ event: Event) {
        guard isEnabled, isStarted else { return }
        #if canImport(TelemetryDeck)
        TelemetryDeck.signal(event.name, parameters: event.parameters)
        #endif
    }

    /// Time from process start to the first screen. Call once, when the main view appears.
    static func trackLaunchTimeOnce() {
        guard !launchTracked, let launchStartedAt else { return }
        launchTracked = true
        track(.launchTime(seconds: Date().timeIntervalSince(launchStartedAt)))
    }

    // MARK: - Daily summary

    /// Sends at most one summary per calendar day, when the app becomes active.
    static func sendDailySummaryIfNeeded(habits: [Habit], cloudSyncOn: Bool, now: Date = .now) {
        guard isEnabled, isStarted else { return }
        let today = Calendar.current.dayKey(for: now).description
        guard UserDefaults.standard.string(forKey: lastSummaryDayKey) != today else { return }
        UserDefaults.standard.set(today, forKey: lastSummaryDayKey)

        let active = habits.filter { !$0.isArchived }
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: now) ?? now
        let dueYesterday = active.filter { $0.isActive(on: yesterday) && !$0.isSkipped(on: yesterday) }
        let doneYesterday = dueYesterday.filter { $0.isCompleted(on: yesterday) }
        let bestStreak = active.map { $0.liveStreak.currentStreak }.max() ?? 0

        let params: [String: String] = [
            "habits": bucket(active.count),
            "dueYesterday": bucket(dueYesterday.count),
            "doneYesterday": bucket(doneYesterday.count),
            "completionYesterday": percentBucket(done: doneYesterday.count, of: dueYesterday.count),
            "bestCurrentStreak": streakBucket(bestStreak),
            "usesReminders": "\(active.contains { !$0.reminderTimes.isEmpty || $0.reminderIntervalMinutes > 0 })",
            "usesIntervalHabits": "\(active.contains { $0.reminderIntervalMinutes > 0 })",
            "usesWeeklyHabits": "\(active.contains { $0.frequency == .weekly })",
            "usesSkip": "\(active.contains { $0.entriesOrEmpty.contains(where: \.isSkipped) })",
            "iCloudSync": "\(cloudSyncOn)",
            "appearance": UserDefaults.standard.string(forKey: "appearanceMode") ?? "system",
            "adFree": "\(PurchaseManager.shared.isAdFree)",
        ]

        Task {
            var params = params
            let settings = await UNUserNotificationCenter.current().notificationSettings()
            params["notificationsAllowed"] = "\(settings.authorizationStatus == .authorized)"
            let hasWidget = await hasInstalledWidget()
            params["hasWidget"] = "\(hasWidget)"
            #if canImport(TelemetryDeck)
            TelemetryDeck.signal("Daily.summary", parameters: params)
            #endif
        }
    }

    /// Whether any of the app's widgets is installed. Uses the callback API; the async one needs iOS 18.
    private static func hasInstalledWidget() async -> Bool {
        await withCheckedContinuation { continuation in
            WidgetCenter.shared.getCurrentConfigurations { result in
                let count = (try? result.get())?.count ?? 0
                continuation.resume(returning: count > 0)
            }
        }
    }

    // MARK: - Buckets (coarse on purpose)

    nonisolated static func bucket(_ n: Int) -> String {
        switch n {
        case ..<1: "0"
        case 1: "1"
        case 2...3: "2-3"
        case 4...6: "4-6"
        case 7...10: "7-10"
        default: "11+"
        }
    }

    nonisolated static func streakBucket(_ n: Int) -> String {
        switch n {
        case ..<1: "0"
        case 1...2: "1-2"
        case 3...6: "3-6"
        case 7...13: "7-13"
        case 14...29: "14-29"
        case 30...99: "30-99"
        default: "100+"
        }
    }

    nonisolated static func percentBucket(done: Int, of total: Int) -> String {
        guard total > 0 else { return "none due" }
        let pct = Double(done) / Double(total)
        switch pct {
        case ..<0.01: return "0%"
        case ..<0.5: return "1-49%"
        case ..<1.0: return "50-99%"
        default: return "100%"
        }
    }

    nonisolated static func launchBucket(_ seconds: TimeInterval) -> String {
        switch seconds {
        case ..<0.5: "<0.5s"
        case ..<1: "0.5-1s"
        case ..<2: "1-2s"
        case ..<4: "2-4s"
        default: "4s+"
        }
    }
}
