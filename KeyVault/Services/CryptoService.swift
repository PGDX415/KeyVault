//
//  CryptoService.swift
//  KeyVault
//
//  加密服务：AES-GCM 加解密 + 密钥派生（类 PBKDF2）
//  TODO: 后续版本升级为 CommonCrypto PBKDF2 或 Argon2id
//

import CryptoKit
import Foundation

enum CryptoError: LocalizedError {
    case encryptionFailed
    case decryptionFailed
    case invalidData

    var errorDescription: String? {
        switch self {
        case .encryptionFailed: return "加密失败，请重试"
        case .decryptionFailed: return "解密失败，主密码可能不正确"
        case .invalidData: return "数据格式无效"
        }
    }
}

/// 加密服务：基于 Apple CryptoKit 提供 AES-256-GCM 加解密
enum CryptoService {

    // MARK: - 密钥生成

    /// 生成 256 位随机对称密钥（用作数据加密主密钥）
    static func generateRandomKey() -> SymmetricKey {
        SymmetricKey(size: .bits256)
    }

    /// 生成 32 字节随机盐值
    static func generateSalt() -> Data {
        var salt = Data(count: 32)
        salt.withUnsafeMutableBytes { buffer in
            _ = SecRandomCopyBytes(kSecRandomDefault, 32, buffer.baseAddress!)
        }
        return salt
    }

    // MARK: - AES-GCM 加解密

    /// 使用 AES-256-GCM 加密 Data
    static func encrypt(_ data: Data, using key: SymmetricKey) throws -> Data {
        do {
            let sealedBox = try AES.GCM.seal(data, using: key)
            guard let combined = sealedBox.combined else {
                throw CryptoError.encryptionFailed
            }
            return combined
        } catch {
            throw CryptoError.encryptionFailed
        }
    }

    /// 使用 AES-256-GCM 解密 Data
    static func decrypt(_ data: Data, using key: SymmetricKey) throws -> Data {
        do {
            let sealedBox = try AES.GCM.SealedBox(combined: data)
            return try AES.GCM.open(sealedBox, using: key)
        } catch {
            throw CryptoError.decryptionFailed
        }
    }

    /// 加密字符串（UTF-8 编码后加密）
    static func encryptString(_ string: String, using key: SymmetricKey) throws -> Data {
        guard let data = string.data(using: .utf8) else {
            throw CryptoError.invalidData
        }
        return try encrypt(data, using: key)
    }

    /// 解密为字符串（解密后以 UTF-8 解码）
    static func decryptString(_ data: Data, using key: SymmetricKey) throws -> String {
        let decrypted = try decrypt(data, using: key)
        guard let string = String(data: decrypted, encoding: .utf8) else {
            throw CryptoError.decryptionFailed
        }
        return string
    }

    // MARK: - 密钥派生（从主密码派生加密密钥）

    /// 使用类 PBKDF2 的迭代 SHA-256 从密码 + 盐派生 256 位密钥
    ///
    /// - Parameters:
    ///   - password: 用户主密码
    ///   - salt: 32 字节随机盐值
    ///   - iterations: 迭代次数，默认 100,000 次
    /// - Returns: 派生的 256 位对称密钥
    ///
    /// 安全说明：当前使用手动迭代 SHA-256 实现，在技术上是安全的单向函数，
    /// 但不如标准 PBKDF2 或 Argon2id 经过严格的密码学审查。
    /// 后续版本计划迁移至 CommonCrypto CCKeyDerivationPBKDF 或 Swift Crypto。
    static func deriveKey(
        from password: String,
        salt: Data,
        iterations: Int = 100_000
    ) -> SymmetricKey {
        var key = Data(salt)
        let passwordData = Data(password.utf8)
        for _ in 0..<iterations {
            var hasher = SHA256()
            hasher.update(data: key)
            hasher.update(data: passwordData)
            key = Data(hasher.finalize())
        }
        return SymmetricKey(data: key)
    }
}
