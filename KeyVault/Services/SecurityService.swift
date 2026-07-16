//
//  SecurityService.swift
//  KeyVault
//
//  安全服务：统一管理应用锁定状态、密钥派生、数据加解密
//
//  架构：
//  - 首次设置：生成随机主密钥 → 存入 Keychain（生物识别保护）
//    → 用主密码派生密钥包裹主密钥 → 存入 Keychain（无生物识别保护，备用）
//  - 日常解锁：Face ID / Touch ID → 从 Keychain 读取主密钥
//  - 密码备用：输入主密码 → 读取盐值 → 派生密钥 → 解包主密钥
//  - 数据加解密：所有敏感字段通过主密钥 AES-256-GCM 加解密
//

import Foundation
import CryptoKit
import LocalAuthentication
import Observation

/// 安全服务单例：全局管理应用安全状态
@MainActor
@Observable
final class SecurityService {

    static let shared = SecurityService()

    // MARK: - 状态

    /// 保险箱是否已解锁（内存中持有主密钥）
    private(set) var isUnlocked = false

    /// 是否已完成首次主密码设置
    private(set) var isSetupComplete = false

    /// 是否有密码错误（用于 UI 提示）
    var hasPasswordError = false

    /// 内存中持有的主密钥（加解密用），lock() 时清空
    private var masterKey: SymmetricKey?

    // MARK: - Keychain 键名

    private let masterKeyTag = "com.keyvault.masterKey"
    private let wrappedKeyTag = "com.keyvault.wrappedMasterKey"
    private let saltTag = "com.keyvault.passwordSalt"

    // MARK: - 初始化

    private init() {
        // 检查钥匙串中是否有包裹密钥 → 判断是否已完成初始设置
        isSetupComplete = KeychainService.exists(key: wrappedKeyTag)
    }

    // MARK: - 生物识别可用性

    /// 设备是否支持 Face ID / Touch ID
    var isBiometricAvailable: Bool {
        let context = LAContext()
        var error: NSError?
        return context.canEvaluatePolicy(
            .deviceOwnerAuthenticationWithBiometrics,
            error: &error
        )
    }

    /// 生物识别类型描述
    var biometricTypeName: String {
        let context = LAContext()
        var error: NSError?
        guard context.canEvaluatePolicy(
            .deviceOwnerAuthenticationWithBiometrics,
            error: &error
        ) else {
            return "生物识别"
        }

        switch context.biometryType {
        case .faceID:
            return "面容 ID"
        case .touchID:
            return "触控 ID"
        default:
            return "生物识别"
        }
    }

    // MARK: - 初始设置

    /// 使用主密码完成首次设置
    ///
    /// 流程：
    /// 1. 生成随机 256 位主密钥
    /// 2. 主密钥明文存入 Keychain（受生物识别保护）→ 日常快速解锁
    /// 3. 生成随机盐值
    /// 4. 从主密码 + 盐值派生密钥
    /// 5. 用派生密钥加密主密钥 → 包裹密钥存入 Keychain（备用解锁）
    /// 6. 盐值存入 Keychain
    ///
    /// - Parameter password: 用户设置的主密码（需足够强度）
    func setupMasterPassword(_ password: String) throws {
        // 1. 生成随机主密钥
        let key = CryptoService.generateRandomKey()

        // 2. 主密钥明文存入 Keychain（生物识别保护）
        let rawKey = key.withUnsafeBytes { Data($0) }
        try KeychainService.storeBiometricProtected(key: masterKeyTag, data: rawKey)

        // 3. 生成盐值
        let salt = CryptoService.generateSalt()

        // 4. 从主密码派生密钥
        let derivedKey = CryptoService.deriveKey(from: password, salt: salt)

        // 5. 用派生密钥包裹主密钥
        let wrappedKey = try CryptoService.encrypt(rawKey, using: derivedKey)
        try KeychainService.store(key: wrappedKeyTag, data: wrappedKey)

        // 6. 存储盐值
        try KeychainService.store(key: saltTag, data: salt)

        // 7. 设置内存状态
        self.masterKey = key
        self.isUnlocked = true
        self.isSetupComplete = true
        self.hasPasswordError = false
    }

    // MARK: - 解锁

    /// 使用生物识别解锁（Face ID / Touch ID）
    ///
    /// 系统自动弹出生物识别对话框，用户验证通过后从 Keychain 读取主密钥
    func unlockWithBiometrics() async throws {
        let keyData = try KeychainService.readBiometricProtected(
            key: masterKeyTag,
            prompt: "使用 \(biometricTypeName) 解锁密钥阁"
        )
        self.masterKey = SymmetricKey(data: keyData)
        self.isUnlocked = true
        self.hasPasswordError = false
    }

    /// 使用主密码解锁（生物识别失败时的备用方案）
    ///
    /// - Parameter password: 用户输入的主密码
    /// - Throws: 密码错误时抛出 decryptionFailed
    func unlockWithPassword(_ password: String) throws {
        // 读取包裹密钥和盐值
        let wrappedKey: Data
        let salt: Data
        do {
            wrappedKey = try KeychainService.read(key: wrappedKeyTag)
            salt = try KeychainService.read(key: saltTag)
        } catch {
            hasPasswordError = true
            throw error
        }

        // 从密码 + 盐值派生密钥
        let derivedKey = CryptoService.deriveKey(from: password, salt: salt)

        // 尝试解包主密钥（密码错误时解密失败）
        let rawKey: Data
        do {
            rawKey = try CryptoService.decrypt(wrappedKey, using: derivedKey)
        } catch {
            hasPasswordError = true
            throw CryptoError.decryptionFailed
        }

        self.masterKey = SymmetricKey(data: rawKey)
        self.isUnlocked = true
        self.hasPasswordError = false
    }

    /// 锁定保险箱：清除内存中的主密钥
    func lock() {
        self.masterKey = nil
        self.isUnlocked = false
    }

    // MARK: - 数据加解密

    /// 加密 Data
    func encrypt(_ data: Data) throws -> Data {
        guard let key = masterKey else {
            throw CryptoError.encryptionFailed
        }
        return try CryptoService.encrypt(data, using: key)
    }

    /// 解密 Data
    func decrypt(_ data: Data) throws -> Data {
        guard let key = masterKey else {
            throw CryptoError.decryptionFailed
        }
        return try CryptoService.decrypt(data, using: key)
    }

    /// 加密字符串
    func encryptString(_ string: String) throws -> Data {
        guard let key = masterKey else {
            throw CryptoError.encryptionFailed
        }
        return try CryptoService.encryptString(string, using: key)
    }

    /// 解密字符串
    func decryptString(_ data: Data) throws -> String {
        guard let key = masterKey else {
            throw CryptoError.decryptionFailed
        }
        return try CryptoService.decryptString(data, using: key)
    }
}
