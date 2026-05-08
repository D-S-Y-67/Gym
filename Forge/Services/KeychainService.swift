import Foundation
import Security

/// Keychain wrapper for the Qwen API key. Single key, device-local
/// (`kSecAttrAccessibleWhenUnlockedThisDeviceOnly`), no iCloud sync.
///
/// Calls are non-isolated — the underlying `SecItem*` APIs are thread-safe
/// and can be invoked from any actor. `QwenService` reads the key on every
/// request so a Disconnect in Profile takes effect immediately.
enum KeychainService {

    /// Bundle-prefixed service name. If the bundle id changes the entry is
    /// effectively orphaned, which is the right behavior — we'd rather
    /// re-prompt than reuse a key for a different app.
    private static let service = "com.placeholder.forge.qwen"
    private static let account = "apiKey"

    enum KeychainError: Error, LocalizedError {
        case unexpectedStatus(OSStatus)
        case stringEncoding

        var errorDescription: String? {
            switch self {
            case .unexpectedStatus(let status):
                return "Keychain error \(status). Try again or restart the app."
            case .stringEncoding:
                return "Couldn't encode the key. Make sure it's plain text."
            }
        }
    }

    /// Persists `apiKey`, replacing any existing entry.
    static func save(_ apiKey: String) throws {
        guard let data = apiKey.data(using: .utf8) else {
            throw KeychainError.stringEncoding
        }

        // Best-effort delete first so we always have a clean add (avoids
        // duplicate-item errors and update-vs-insert branching).
        let deleteQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        SecItemDelete(deleteQuery as CFDictionary)

        let attributes: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
            kSecValueData as String: data
        ]

        let status = SecItemAdd(attributes as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw KeychainError.unexpectedStatus(status)
        }
    }

    /// Returns the stored key, or `nil` if none exists.
    static func load() -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess,
              let data = result as? Data,
              let key = String(data: data, encoding: .utf8) else {
            return nil
        }
        return key
    }

    /// Removes the stored key. No-op if no key exists.
    static func delete() throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        let status = SecItemDelete(query as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.unexpectedStatus(status)
        }
    }

    /// Cheap presence check. Equivalent to `load() != nil` but doesn't
    /// surface the actual secret to the caller.
    static func hasKey() -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        let status = SecItemCopyMatching(query as CFDictionary, nil)
        return status == errSecSuccess
    }
}
