//
//  Account.swift
//  KeyVault
//
//  保险箱账户数据模型——支持多种分类，所有敏感字段加密存储
//

import Foundation
import SwiftData
import SwiftUI

// MARK: - 记录分类

/// 保险箱记录分类
enum VaultCategory: String, CaseIterable, Codable {
    case general = "通用凭证"
    case loginPassword = "登陆密码"
    case emailAccount = "电子邮件账户"
    case internetAccount = "互联网账户"
    case bankAccount = "银行账户"
    case creditCard = "信用卡"
    case membership = "会员"
    case socialSecurity = "社保"
    case driversLicense = "驾照"
    case idCard = "身份证"
    case passport = "护照"
    case wifiRouter = "Wi-Fi路由器"
    case insurance = "保险"
    case isp = "网路服务提供商"
    case cryptoWallet = "加密币钱包"

    /// SF Symbol 图标
    var iconName: String {
        switch self {
        case .general:          return "globe"
        case .loginPassword:    return "key.fill"
        case .emailAccount:     return "envelope.fill"
        case .internetAccount:  return "safari.fill"
        case .bankAccount:      return "building.columns.fill"
        case .creditCard:       return "creditcard.fill"
        case .membership:       return "person.fill.checkmark"
        case .socialSecurity:   return "building.2.fill"
        case .driversLicense:   return "car.fill"
        case .idCard:           return "person.text.rectangle.fill"
        case .passport:         return "book.fill"
        case .wifiRouter:       return "wifi"
        case .insurance:        return "umbrella.fill"
        case .isp:              return "network"
        case .cryptoWallet:     return "bitcoinsign.circle"
        }
    }

    /// 分类对应颜色
    var color: Color {
        switch self {
        case .general:          return .purple
        case .loginPassword:    return .orange
        case .emailAccount:     return .blue
        case .internetAccount:  return .cyan
        case .bankAccount:      return .blue
        case .creditCard:       return .red
        case .membership:       return .orange
        case .socialSecurity:   return .teal
        case .driversLicense:   return .indigo
        case .idCard:           return .purple
        case .passport:         return .green
        case .wifiRouter:       return .blue
        case .insurance:        return .mint
        case .isp:              return .gray
        case .cryptoWallet:     return .orange
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
    var id: UUID = UUID()

    // ======================== 分类 ========================

    /// 记录分类（明文存储，用于查询过滤；旧数据默认归类为通用凭证）
    var category: String = VaultCategory.general.rawValue

    // ======================== 通用字段（所有分类共用）========================

    /// AES-GCM 加密后的名称
    var encryptedName: Data = Data()

    /// AES-GCM 加密后的用户名/账号
    var encryptedUsername: Data = Data()

    /// AES-GCM 加密后的密码
    var encryptedPassword: Data = Data()

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

    // ======================== 扩展加密字段（各分类专属）========================

    /// 姓名（身份证/驾照/护照/社保）
    var encryptedFullName: Data?
    /// 证件号码（身份证号/驾照号/护照号/社保号/会员号）
    var encryptedDocumentNumber: Data?
    /// 签发机关 / 发卡机构
    var encryptedIssuingAuthority: Data?
    /// Wi-Fi 名称（SSID）
    var encryptedSSID: Data?
    /// Wi-Fi 安全类型（WPA2/WPA3/WEP）
    var encryptedSecurityType: Data?
    /// 信用卡账单日
    var encryptedBillingDay: Data?
    /// 信用卡还款日
    var encryptedRepaymentDay: Data?
    /// 信用卡额度
    var encryptedCreditLimit: Data?
    /// 会员等级
    var encryptedMembershipLevel: Data?
    /// 保险险种
    var encryptedInsuranceType: Data?
    /// 被保人
    var encryptedInsuredPerson: Data?
    /// 加密币钱包地址
    var encryptedWalletAddress: Data?
    /// 网络类型（加密币）/ ISP 套餐
    var encryptedNetworkType: Data?
    /// 邮件服务器
    var encryptedServer: Data?
    /// 邮件端口
    var encryptedPort: Data?

    // ======================== 非敏感元数据 ========================

    /// 创建时间
    var createdAt: Date = Date()

    /// 最后修改时间
    var modifiedAt: Date = Date()

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
        encryptedFullName: Data? = nil,
        encryptedDocumentNumber: Data? = nil,
        encryptedIssuingAuthority: Data? = nil,
        encryptedSSID: Data? = nil,
        encryptedSecurityType: Data? = nil,
        encryptedBillingDay: Data? = nil,
        encryptedRepaymentDay: Data? = nil,
        encryptedCreditLimit: Data? = nil,
        encryptedMembershipLevel: Data? = nil,
        encryptedInsuranceType: Data? = nil,
        encryptedInsuredPerson: Data? = nil,
        encryptedWalletAddress: Data? = nil,
        encryptedNetworkType: Data? = nil,
        encryptedServer: Data? = nil,
        encryptedPort: Data? = nil,
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
        self.encryptedFullName = encryptedFullName
        self.encryptedDocumentNumber = encryptedDocumentNumber
        self.encryptedIssuingAuthority = encryptedIssuingAuthority
        self.encryptedSSID = encryptedSSID
        self.encryptedSecurityType = encryptedSecurityType
        self.encryptedBillingDay = encryptedBillingDay
        self.encryptedRepaymentDay = encryptedRepaymentDay
        self.encryptedCreditLimit = encryptedCreditLimit
        self.encryptedMembershipLevel = encryptedMembershipLevel
        self.encryptedInsuranceType = encryptedInsuranceType
        self.encryptedInsuredPerson = encryptedInsuredPerson
        self.encryptedWalletAddress = encryptedWalletAddress
        self.encryptedNetworkType = encryptedNetworkType
        self.encryptedServer = encryptedServer
        self.encryptedPort = encryptedPort
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

    // 银行/信用卡专属字段
    var bankName: String
    var cardNumber: String
    var cardholderName: String
    var cardType: CardType
    var branch: String
    var phone: String
    var cvv: String
    var expiryDate: String

    // 信用卡扩展字段
    var billingDay: String
    var repaymentDay: String
    var creditLimit: String

    // 证件类字段（身份证/驾照/护照/社保）
    var fullName: String
    var documentNumber: String
    var issuingAuthority: String

    // Wi-Fi 字段
    var ssid: String
    var securityType: String

    // 会员字段
    var membershipLevel: String

    // 保险字段
    var insuranceType: String
    var insuredPerson: String

    // 加密币字段
    var walletAddress: String
    var networkType: String

    // 邮箱字段
    var server: String
    var port: String

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

    // 银行/信用卡
    var bankName: String = ""
    var cardNumber: String = ""
    var cardholderName: String = ""
    var cardType: CardType = .debit
    var branch: String = ""
    var phone: String = ""
    var cvv: String = ""
    var expiryDate: String = ""
    var billingDay: String = ""
    var repaymentDay: String = ""
    var creditLimit: String = ""

    // 证件类
    var fullName: String = ""
    var documentNumber: String = ""
    var issuingAuthority: String = ""

    // Wi-Fi
    var ssid: String = ""
    var securityType: String = ""

    // 会员
    var membershipLevel: String = ""

    // 保险
    var insuranceType: String = ""
    var insuredPerson: String = ""

    // 加密币
    var walletAddress: String = ""
    var networkType: String = ""

    // 邮箱
    var server: String = ""
    var port: String = ""

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
        self.billingDay = display.billingDay
        self.repaymentDay = display.repaymentDay
        self.creditLimit = display.creditLimit
        self.fullName = display.fullName
        self.documentNumber = display.documentNumber
        self.issuingAuthority = display.issuingAuthority
        self.ssid = display.ssid
        self.securityType = display.securityType
        self.membershipLevel = display.membershipLevel
        self.insuranceType = display.insuranceType
        self.insuredPerson = display.insuredPerson
        self.walletAddress = display.walletAddress
        self.networkType = display.networkType
        self.server = display.server
        self.port = display.port
    }

    /// 空白表单（用于新增）
    init() {}

    /// 表单是否有效
    var isValid: Bool {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return false }

        switch category {
        case .bankAccount:
            return !cardNumber.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        case .creditCard:
            return !cardNumber.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        case .wifiRouter:
            return !ssid.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        case .cryptoWallet:
            return !walletAddress.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        case .idCard, .driversLicense, .passport, .socialSecurity:
            return !documentNumber.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        default:
            return !username.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
                   !password.isEmpty
        }
    }
}
