//
//  KeychainService.swift
//  KeyVault
//
//  钥匙串服务：安全存储主密钥材料，支持生物识别保护
//

import Foundation
import Security
import LocalAuthentication

enum KeychainError: LocalizedError {
    case saveFailed
    case readFailed
    case deleteFailed
    case itemNotFound
    case biometricNotAvailable(message: String)

    var errorDescription: String? {
        switch self {
        case .saveFailed:
            return "钥匙串保存失败"
        case .readFailed:
            return "钥匙串读取失败"
        case .deleteFailed:
            return "钥匙串删除失败"
        case .itemNotFound:
            return "未找到存储的密钥数据"
        case .biometricNotAvailable(let message):
            return message
        }
    }
}

/// 钥匙串服务：管理加密密钥的安全存储
///
/// 存储三类数据：
/// 1. 主密钥 —— 受生物识别保护（Face ID / Touch ID），日常快速解锁
///    仅限本设备，不可同步（Secure Enclave 绑定）
/// 2. 包裹密钥 —— 用主密码派生的密钥加密后的主密钥，用于密码备用解锁
///    通过 iCloud 钥匙串同步，换设备后可输主密码解锁
/// 3. 密码盐值 —— 用于从主密码重新派生解密密钥
///    通过 iCloud 钥匙串同步，与包裹密钥配套
enum KeychainService {

    private static let service = "com.gongdexin.paul.KeyVault"

    // MARK: - 存储（受生物识别保护，本设备仅限）

    /// 存储数据到钥匙串，访问时需通过 Face ID / Touch ID 验证
    /// 生物识别密钥绑定 Secure Enclave，不可跨设备同步
    static func storeBiometricProtected(key: String, data: Data) throws {
        guard let accessControl = SecAccessControlCreateWithFlags(
            nil,
            kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
            .biometryAny,
            nil
        ) else {
            throw KeychainError.saveFailed
        }

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            kSecAttrAccessControl as String: accessControl
        ]

        SecItemDelete(query as CFDictionary)

        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw KeychainError.saveFailed
        }
    }

    // MARK: - 存储（可 iCloud 同步）

    /// 存储数据到钥匙串，设备解锁即可读取，通过 iCloud 钥匙串跨设备同步
    /// 用于包裹密钥和盐值——换设备后可输主密码解锁
    static func store(key: String, data: Data) throws {
        try storeSync(key: key, data: data)
    }

    /// 内部实现：可同步存储
    private static func storeSync(key: String, data: Data) throws {
        // 先尝试删除旧数据（含旧的非同步版本，做迁移）
        deleteCompat(key: key)

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlocked,
            kSecAttrSynchronizable as String: true
        ]

        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw KeychainError.saveFailed
        }
    }

    // MARK: - 读取（触发生物识别提示）

    /// 读取受生物识别保护的数据，系统自动弹出 Face ID / Touch ID 提示
    static func readBiometricProtected(key: String, prompt: String = "使用面容 ID 解锁密钥阁") throws -> Data {
        let context = LAContext()
        context.localizedReason = prompt

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
            kSecUseAuthenticationContext as String: context
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        if status == errSecUserCanceled {
            throw KeychainError.readFailed
        }

        guard status == errSecSuccess, let data = result as? Data else {
            if status == errSecInteractionNotAllowed {
                throw KeychainError.biometricNotAvailable(
                    message: "生物识别不可用，请使用主密码解锁"
                )
            }
            throw KeychainError.readFailed
        }

        return data
    }

    // MARK: - 读取（无生物识别提示，兼容迁移）

    /// 读取存储在钥匙串中的数据（无需生物识别验证）
    /// 优先读取 iCloud 同步版本，兼容旧的非同步版本
    static func read(key: String) throws -> Data {
        // 先尝试 iCloud 同步版本
        if let data = try? readSync(key: key) {
            return data
        }
        // 兼容旧版本（非同步），读取后自动迁移到同步版本
        if let data = try? readCompat(key: key) {
            try? storeSync(key: key, data: data)
            return data
        }
        throw KeychainError.readFailed
    }

    /// 读取 iCloud 同步版本
    private static func readSync(key: String) throws -> Data {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
            kSecAttrSynchronizable as String: true
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess, let data = result as? Data else {
            throw KeychainError.readFailed
        }
        return data
    }

    /// 读取旧版本（非同步兼容）
    private static func readCompat(key: String) throws -> Data {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess, let data = result as? Data else {
            throw KeychainError.readFailed
        }
        return data
    }

    // MARK: - 删除

    /// 删除指定 key 的数据（含同步和非同步版本）
    static func delete(key: String) throws {
        deleteCompat(key: key)
    }

    /// 删除所有版本（同步 + 非同步）
    private static func deleteCompat(key: String) {
        // 非同步版本
        let queryBase: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key
        ]
        SecItemDelete(queryBase as CFDictionary)

        // iCloud 同步版本
        var querySync = queryBase
        querySync[kSecAttrSynchronizable as String] = true
        SecItemDelete(querySync as CFDictionary)
    }

    // MARK: - 检查存在

    /// 检查指定 key 是否已存储数据（含同步和非同步版本）
    static func exists(key: String) -> Bool {
        // 检查 iCloud 同步版本
        let querySync: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecMatchLimit as String: kSecMatchLimitOne,
            kSecReturnData as String: false,
            kSecAttrSynchronizable as String: true
        ]
        if SecItemCopyMatching(querySync as CFDictionary, nil) == errSecSuccess {
            return true
        }

        // 检查旧的非同步版本
        let queryCompat: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecMatchLimit as String: kSecMatchLimitOne,
            kSecReturnData as String: false
        ]
        return SecItemCopyMatching(queryCompat as CFDictionary, nil) == errSecSuccess
    }
}
