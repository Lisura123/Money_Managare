import Foundation
import Security

enum KeychainError: Error { case saveFailed, readFailed, deleteFailed }

struct KeychainService {

    // MARK: - Public API

    static func save(_ value: String, for key: String) throws {
#if targetEnvironment(simulator)
        UserDefaults.standard.set(value, forKey: key)
#else
        let data = Data(value.utf8)
        let query: [CFString: Any] = [
            kSecClass:          kSecClassGenericPassword,
            kSecAttrAccount:    key,
            kSecAttrAccessible: kSecAttrAccessibleAfterFirstUnlock,
            kSecValueData:      data
        ]
        SecItemDelete(query as CFDictionary)
        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else { throw KeychainError.saveFailed }
#endif
    }

    static func read(for key: String) throws -> String {
#if targetEnvironment(simulator)
        guard let value = UserDefaults.standard.string(forKey: key) else {
            throw KeychainError.readFailed
        }
        return value
#else
        let query: [CFString: Any] = [
            kSecClass:          kSecClassGenericPassword,
            kSecAttrAccount:    key,
            kSecAttrAccessible: kSecAttrAccessibleAfterFirstUnlock,
            kSecReturnData:     true,
            kSecMatchLimit:     kSecMatchLimitOne
        ]
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess, let data = result as? Data else {
            throw KeychainError.readFailed
        }
        return String(decoding: data, as: UTF8.self)
#endif
    }

    static func delete(for key: String) {
#if targetEnvironment(simulator)
        UserDefaults.standard.removeObject(forKey: key)
#else
        let query: [CFString: Any] = [
            kSecClass:       kSecClassGenericPassword,
            kSecAttrAccount: key
        ]
        SecItemDelete(query as CFDictionary)
#endif
    }
}
