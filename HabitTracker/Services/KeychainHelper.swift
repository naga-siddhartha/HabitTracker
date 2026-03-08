import Foundation
import Security

/// Simple Keychain access for storing the Sign in with Apple user identifier.
enum KeychainHelper {
    private static let serviceName = "com.rituallog.app"
    private static let userIdKey = "userId"
    
    static func save(userId: String) -> Bool {
        guard let data = userId.data(using: .utf8) else { return false }
        delete(userIdKey)
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: userIdKey,
            kSecValueData as String: data
        ]
        return SecItemAdd(query as CFDictionary, nil) == errSecSuccess
    }
    
    static func loadUserId() -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: userIdKey,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess, let data = result as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }
    
    static func deleteUserId() -> Bool {
        delete(userIdKey)
    }
    
    private static func delete(_ account: String) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: account
        ]
        return SecItemDelete(query as CFDictionary) == errSecSuccess || SecItemDelete(query as CFDictionary) == errSecItemNotFound
    }
}
