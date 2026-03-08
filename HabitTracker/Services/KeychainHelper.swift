import Foundation
import Security

/// Simple Keychain access for storing the Sign in with Apple user identifier and optional display info.
enum KeychainHelper {
    // MARK: - Public API

    nonisolated static func save(userId: String, displayName: String? = nil) -> Bool {
        guard let data = userId.data(using: .utf8) else { return false }
        _ = delete("userId")
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: "com.rituallog.app",
            kSecAttrAccount as String: "userId",
            kSecValueData as String: data
        ]
        guard SecItemAdd(query as CFDictionary, nil) == errSecSuccess else { return false }
        if let displayName = displayName, !displayName.isEmpty {
            _ = delete("userDisplayName")
            guard let data = displayName.data(using: .utf8) else { return true }
            let nameQuery: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrService as String: "com.rituallog.app",
                kSecAttrAccount as String: "userDisplayName",
                kSecValueData as String: data
            ]
            _ = SecItemAdd(nameQuery as CFDictionary, nil)
        }
        return true
    }
    
    nonisolated static func loadUserId() -> String? {
        load(account: "userId")
    }
    
    nonisolated static func loadUserDisplayName() -> String? {
        load(account: "userDisplayName")
    }
    
    nonisolated static func deleteUserId() -> Bool {
        _ = delete("userDisplayName")
        return delete("userId")
    }
    
    private nonisolated static func load(account: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: "com.rituallog.app",
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess, let data = result as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }
    
    private nonisolated static func delete(_ account: String) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: "com.rituallog.app",
            kSecAttrAccount as String: account
        ]
        return SecItemDelete(query as CFDictionary) == errSecSuccess || SecItemDelete(query as CFDictionary) == errSecItemNotFound
    }
}
