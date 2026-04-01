import Foundation
import Security

/// Simple Keychain access for storing the Sign in with Apple user identifier and optional display info.
enum KeychainHelper {
    /// Current service (matches app identity). Use this for all new reads/writes.
    nonisolated private static let keychainService = "com.nagasiddharthadonepudi.HabitTracker.keychain"
    /// Legacy service from Ritual Log era; one-time migration copies to `keychainService` then removes.
    nonisolated private static let legacyKeychainService = "com.rituallog.app"

    // MARK: - Public API

    nonisolated static func save(userId: String, displayName: String? = nil) -> Bool {
        guard let data = userId.data(using: .utf8) else { return false }
        _ = delete(account: "userId")
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: "userId",
            kSecValueData as String: data
        ]
        guard SecItemAdd(query as CFDictionary, nil) == errSecSuccess else { return false }
        if let displayName = displayName, !displayName.isEmpty {
            _ = delete(account: "userDisplayName")
            guard let nameData = displayName.data(using: .utf8) else { return true }
            let nameQuery: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrService as String: keychainService,
                kSecAttrAccount as String: "userDisplayName",
                kSecValueData as String: nameData
            ]
            _ = SecItemAdd(nameQuery as CFDictionary, nil)
        }
        return true
    }

    nonisolated static func loadUserId() -> String? {
        migrateLegacyIfNeeded()
        return load(account: "userId")
    }

    nonisolated static func loadUserDisplayName() -> String? {
        migrateLegacyIfNeeded()
        return load(account: "userDisplayName")
    }

    nonisolated static func deleteUserId() -> Bool {
        _ = delete(account: "userDisplayName")
        return delete(account: "userId")
    }

    /// If data exists only under the legacy service, copy to the current service and remove legacy entries.
    private nonisolated static func migrateLegacyIfNeeded() {
        if loadFromService(keychainService, account: "userId") != nil { return }
        guard let userId = loadFromService(legacyKeychainService, account: "userId") else { return }
        let displayName = loadFromService(legacyKeychainService, account: "userDisplayName")
        _ = save(userId: userId, displayName: displayName)
        _ = deleteFromService(legacyKeychainService, account: "userId")
        _ = deleteFromService(legacyKeychainService, account: "userDisplayName")
    }

    private nonisolated static func load(account: String) -> String? {
        loadFromService(keychainService, account: account)
    }

    private nonisolated static func loadFromService(_ service: String, account: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess, let data = result as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    private nonisolated static func delete(account: String) -> Bool {
        deleteFromService(keychainService, account: account)
    }

    private nonisolated static func deleteFromService(_ service: String, account: String) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        let status = SecItemDelete(query as CFDictionary)
        return status == errSecSuccess || status == errSecItemNotFound
    }
}
