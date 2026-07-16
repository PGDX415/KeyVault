//
//  Account.swift
//  KeyVault
//
//  保险箱账户数据模型——支持多种分类，所有敏感字段加密存储
//

import Foundation
import SwiftData

// MARK: - 记录分类

/// 保险箱记录分类（可扩展）
enum VaultCategory: String, CaseIterable, Codable {
    case general = "通用凭证"
    case bankAccount = "银行账户"

    /// 用于 UI 展示的 SF Symbol 图标
    var iconName: String {
        switch self {
        case .general: return "globe"
        case .bankAccount: return "building.columns.fill"
        }
    }

    /// 分类对应颜色
    var color: String {
        switch self {
        case .general: return "purple"
        case .bankAccount: return "blue"
        }
    }
}

// MARK: - 银行卡类型

/// 银行卡类型
enum CardType: String, CaseIterable, Codable {
    case debit = "借记卡"
    case credit = "信用卡"
    case savings = "储蓄卡"
}

// MARK: - SwiftData 持久化模型

/// SwiftData 持久化模型：存储加密后的账户数据
/// 支持多种分类（通用凭证、银行账户等），各分类的专属字段以可选形式存在
@Model
final class Account {
    @Attribute(.unique) var id: UUID

    // ======================== 分类 ========================

    /// 记录分类（明文存储，用于查询过滤；旧数据默认归类为通用凭证）
    var category: String = VaultCategory.general.rawValue

    // ======================== 通用字段（所有分类共用）========================

    /// AES-GCM 加密后的名称
    var encryptedName: Data

    /// AES-GCM 加密后的用户名/账号
    var encryptedUsername: Data

    /// AES-GCM 加密后的密码
    var encryptedPassword: Data

    /// AES-GCM 加密后的网址（可选）
    var encryptedURL: Data?

    /// AES-GCM 加密后的备注（可选）
    var encryptedNotes: Data?

    // ======================== 银行账户专属字段（可选）========================

    /// AES-GCM 加密后的银行名称
    var encryptedBankName: Data?

    /// AES-GCM 加密后的银行卡号
    var encryptedCardNumber: Data?

    /// AES-GCM 加密后的户名
    var encryptedCardholderName: Data?

    /// AES-GCM 加密后的卡类型（借记卡/信用卡/储蓄卡）
    var encryptedCardType: Data?

    /// AES-GCM 加密后的开户行
    var encryptedBranch: Data?

    /// AES-GCM 加密后的预留手机号
    var encryptedPhone: Data?

    /// AES-GCM 加密后的 CVV 安全码
    var encryptedCVV: Data?

    /// AES-GCM 加密后的有效期
    var encryptedExpiryDate: Data?

    // ======================== 非敏感元数据 ========================

    /// 创建时间
    var createdAt: Date

    /// 最后修改时间
    var modifiedAt: Date

    init(
        id: UUID = UUID(),
        category: String = VaultCategory.general.rawValue,
        encryptedName: Data,
        encryptedUsername: Data,
        encryptedPassword: Data,
        encryptedURL: Data? = nil,
        encryptedNotes: Data? = nil,
        encryptedBankName: Data? = nil,
        encryptedCardNumber: Data? = nil,
        encryptedCardholderName: Data? = nil,
        encryptedCardType: Data? = nil,
        encryptedBranch: Data? = nil,
        encryptedPhone: Data? = nil,
        encryptedCVV: Data? = nil,
        encryptedExpiryDate: Data? = nil,
        createdAt: Date = Date(),
        modifiedAt: Date = Date()
    ) {
        self.id = id
        self.category = category
        self.encryptedName = encryptedName
        self.encryptedUsername = encryptedUsername
        self.encryptedPassword = encryptedPassword
        self.encryptedURL = encryptedURL
        self.encryptedNotes = encryptedNotes
        self.encryptedBankName = encryptedBankName
        self.encryptedCardNumber = encryptedCardNumber
        self.encryptedCardholderName = encryptedCardholderName
        self.encryptedCardType = encryptedCardType
        self.encryptedBranch = encryptedBranch
        self.encryptedPhone = encryptedPhone
        self.encryptedCVV = encryptedCVV
        self.encryptedExpiryDate = encryptedExpiryDate
        self.createdAt = createdAt
        self.modifiedAt = modifiedAt
    }
}

// MARK: - UI 展示模型

/// UI 展示用的解密后账户数据（不持久化）
struct AccountDisplay: Identifiable, Hashable {
    let id: UUID

    // 分类
    var category: VaultCategory

    // 通用字段
    var name: String
    var username: String
    var password: String
    var url: String
    var notes: String

    // 银行账户专属字段
    var bankName: String
    var cardNumber: String
    var cardholderName: String
    var cardType: CardType
    var branch: String
    var phone: String
    var cvv: String
    var expiryDate: String

    // 元数据
    let createdAt: Date
    let modifiedAt: Date

    // UI 状态
    var isPasswordVisible: Bool = false
    var isCVVVisible: Bool = false
    var isCardNumberVisible: Bool = false

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: AccountDisplay, rhs: AccountDisplay) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - 编辑表单数据

/// 编辑表单的临时数据模型（用于双向绑定）
struct AccountFormData {
    var category: VaultCategory = .general

    // 通用凭证
    var name: String = ""
    var username: String = ""
    var password: String = ""
    var url: String = ""
    var notes: String = ""

    // 银行账户
    var bankName: String = ""
    var cardNumber: String = ""
    var cardholderName: String = ""
    var cardType: CardType = .debit
    var branch: String = ""
    var phone: String = ""
    var cvv: String = ""
    var expiryDate: String = ""

    /// 从 AccountDisplay 填充编辑数据
    init(from display: AccountDisplay) {
        self.category = display.category
        self.name = display.name
        self.username = display.username
        self.password = display.password
        self.url = display.url
        self.notes = display.notes
        self.bankName = display.bankName
        self.cardNumber = display.cardNumber
        self.cardholderName = display.cardholderName
        self.cardType = display.cardType
        self.branch = display.branch
        self.phone = display.phone
        self.cvv = display.cvv
        self.expiryDate = display.expiryDate
    }

    /// 空白表单（用于新增）
    init() {}

    /// 表单是否有效
    var isValid: Bool {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return false }

        switch category {
        case .general:
            return !username.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
                   !password.isEmpty
        case .bankAccount:
            return !cardNumber.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
    }
}
