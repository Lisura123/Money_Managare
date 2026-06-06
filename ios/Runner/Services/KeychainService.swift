import Foundation
import Security

enum KeychainError: Error { case saveFailed, readFailed, deleteFailed }

struct KeychainService {
    static func save(_ value: String, for key: String) throws {
        let data = Data(value.utf8)
        let query: [CFString: Any] = [
            kSecClass:            kSecClassGenericPassword,
            kSecAttrAccount:      key,
            kSecAttrAccessible:   kSecAttrAccessibleAfterFirstUnlock,
            kSecValueData:        data
        ]
        SecItemDelete(query as CFDictionary)
        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else { throw KeychainError.saveFailed }
    }

    static func read(for key: String) throws -> String {
        let query: [CFString: Any] = [
            kSecClass:            kSecClassGenericPassword,
            kSecAttrAccount:      key,
            kSecAttrAccessible:   kSecAttrAccessibleAfterFirstUnlock,
            kSecReturnData:       true,
            kSecMatchLimit:       kSecMatchLimitOne
        ]
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        if status == errSecItemNotFound { throw KeychainError.readFailed }
        guard status == errSecSuccess, let data = result as? Data else {
            throw KeychainError.readFailed
        }
        return String(decoding: data, as: UTF8.self)
    }

    static func delete(for key: String) {
        let query: [CFString: Any] = [
            kSecClass:       kSecClassGenericPassword,
            kSecAttrAccount: key
        ]
        SecItemDelete(query as CFDictionary)
    }
}
