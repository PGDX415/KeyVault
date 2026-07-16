//
//  AccountViewModel.swift
//  KeyVault
//
//  账户视图模型：连接加密存储和 UI 层
//

import Foundation
import SwiftData
import SwiftUI
import Observation

/// 账户管理视图模型：负责账户的增删改查 + 加密/解密转换
@MainActor
@Observable
final class AccountViewModel {

    // MARK: - 依赖

    private let securityService = SecurityService.shared
    private var modelContext: ModelContext?

    // MARK: - 数据

    /// 解密后的账户列表
    var accounts: [AccountDisplay] = []

    /// 搜索关键词
    var searchText = ""

    /// 是否正在加载
    var isLoading = false

    /// 错误信息
    var errorMessage: String?

    // MARK: - 计算属性

    /// 根据搜索关键词过滤后的账户列表
    var filteredAccounts: [AccountDisplay] {
        if searchText.isEmpty {
            return accounts
        }
        let keyword = searchText.lowercased()
        return accounts.filter {
            $0.name.lowercased().contains(keyword) ||
            $0.username.lowercased().contains(keyword) ||
            $0.cardNumber.lowercased().contains(keyword) ||
            $0.bankName.lowercased().contains(keyword)
        }
    }

    // MARK: - 加解密辅助

    private func decryptOpt(_ data: Data?) throws -> String {
        guard let data else { return "" }
        return try securityService.decryptString(data)
    }

    private func encryptOpt(_ str: String) throws -> Data? {
        str.isEmpty ? nil : try securityService.encryptString(str)
    }

    // MARK: - 配置

    /// 注入 SwiftData ModelContext（由 View 通过 .modelContainer 环境值传入）
    func configure(with context: ModelContext) {
        self.modelContext = context
    }

    // MARK: - 查询

    /// 从 SwiftData 加载所有账户并解密
    func loadAccounts() {
        guard let context = modelContext else {
            errorMessage = "数据库未初始化"
            return
        }

        isLoading = true
        errorMessage = nil

        do {
            let descriptor = FetchDescriptor<Account>(
                sortBy: [SortDescriptor(\.modifiedAt, order: .reverse)]
            )
            let accounts = try context.fetch(descriptor)

            self.accounts = try accounts.map { account in
                let cat = VaultCategory(rawValue: account.category) ?? .general
                return AccountDisplay(
                    id: account.id,
                    category: cat,
                    name: try securityService.decryptString(account.encryptedName),
                    username: try securityService.decryptString(account.encryptedUsername),
                    password: try securityService.decryptString(account.encryptedPassword),
                    url: try decryptOpt(account.encryptedURL),
                    notes: try decryptOpt(account.encryptedNotes),
                    bankName: try decryptOpt(account.encryptedBankName),
                    cardNumber: try decryptOpt(account.encryptedCardNumber),
                    cardholderName: try decryptOpt(account.encryptedCardholderName),
                    cardType: (try account.encryptedCardType.map { raw in
                        CardType(rawValue: try securityService.decryptString(raw)) ?? .debit
                    }) ?? .debit,
                    branch: try decryptOpt(account.encryptedBranch),
                    phone: try decryptOpt(account.encryptedPhone),
                    cvv: try decryptOpt(account.encryptedCVV),
                    expiryDate: try decryptOpt(account.encryptedExpiryDate),
                    billingDay: try decryptOpt(account.encryptedBillingDay),
                    repaymentDay: try decryptOpt(account.encryptedRepaymentDay),
                    creditLimit: try decryptOpt(account.encryptedCreditLimit),
                    fullName: try decryptOpt(account.encryptedFullName),
                    documentNumber: try decryptOpt(account.encryptedDocumentNumber),
                    issuingAuthority: try decryptOpt(account.encryptedIssuingAuthority),
                    ssid: try decryptOpt(account.encryptedSSID),
                    securityType: try decryptOpt(account.encryptedSecurityType),
                    membershipLevel: try decryptOpt(account.encryptedMembershipLevel),
                    insuranceType: try decryptOpt(account.encryptedInsuranceType),
                    insuredPerson: try decryptOpt(account.encryptedInsuredPerson),
                    walletAddress: try decryptOpt(account.encryptedWalletAddress),
                    networkType: try decryptOpt(account.encryptedNetworkType),
                    server: try decryptOpt(account.encryptedServer),
                    port: try decryptOpt(account.encryptedPort),
                    createdAt: account.createdAt,
                    modifiedAt: account.modifiedAt
                )
            }
        } catch {
            errorMessage = "加载账户失败：\(error.localizedDescription)"
        }

        isLoading = false
    }

    // MARK: - 新增

    /// 使用表单数据新增一条记录（自动根据分类加密对应字段）
    func saveAccount(formData: AccountFormData) throws {
        guard let context = modelContext else {
            errorMessage = "数据库未初始化"
            return
        }

        let encryptedName = try securityService.encryptString(formData.name)
        let encryptedUsername = try securityService.encryptString(formData.username)
        let encryptedPassword = try securityService.encryptString(formData.password)
        let encryptedURL = try encryptOpt(formData.url)
        let encryptedNotes = try encryptOpt(formData.notes)
        let encryptedBankName = try encryptOpt(formData.bankName)
        let encryptedCardNumber = try encryptOpt(formData.cardNumber)
        let encryptedCardholderName = try encryptOpt(formData.cardholderName)
        let encryptedCardType = try securityService.encryptString(formData.cardType.rawValue)
        let encryptedBranch = try encryptOpt(formData.branch)
        let encryptedPhone = try encryptOpt(formData.phone)
        let encryptedCVV = try encryptOpt(formData.cvv)
        let encryptedExpiryDate = try encryptOpt(formData.expiryDate)
        let encryptedBillingDay = try encryptOpt(formData.billingDay)
        let encryptedRepaymentDay = try encryptOpt(formData.repaymentDay)
        let encryptedCreditLimit = try encryptOpt(formData.creditLimit)
        let encryptedFullName = try encryptOpt(formData.fullName)
        let encryptedDocumentNumber = try encryptOpt(formData.documentNumber)
        let encryptedIssuingAuthority = try encryptOpt(formData.issuingAuthority)
        let encryptedSSID = try encryptOpt(formData.ssid)
        let encryptedSecurityType = try encryptOpt(formData.securityType)
        let encryptedMembershipLevel = try encryptOpt(formData.membershipLevel)
        let encryptedInsuranceType = try encryptOpt(formData.insuranceType)
        let encryptedInsuredPerson = try encryptOpt(formData.insuredPerson)
        let encryptedWalletAddress = try encryptOpt(formData.walletAddress)
        let encryptedNetworkType = try encryptOpt(formData.networkType)
        let encryptedServer = try encryptOpt(formData.server)
        let encryptedPort = try encryptOpt(formData.port)

        let account = Account(
            category: formData.category.rawValue,
            encryptedName: encryptedName,
            encryptedUsername: encryptedUsername,
            encryptedPassword: encryptedPassword,
            encryptedURL: encryptedURL,
            encryptedNotes: encryptedNotes,
            encryptedBankName: encryptedBankName,
            encryptedCardNumber: encryptedCardNumber,
            encryptedCardholderName: encryptedCardholderName,
            encryptedCardType: encryptedCardType,
            encryptedBranch: encryptedBranch,
            encryptedPhone: encryptedPhone,
            encryptedCVV: encryptedCVV,
            encryptedExpiryDate: encryptedExpiryDate,
            encryptedFullName: encryptedFullName,
            encryptedDocumentNumber: encryptedDocumentNumber,
            encryptedIssuingAuthority: encryptedIssuingAuthority,
            encryptedSSID: encryptedSSID,
            encryptedSecurityType: encryptedSecurityType,
            encryptedBillingDay: encryptedBillingDay,
            encryptedRepaymentDay: encryptedRepaymentDay,
            encryptedCreditLimit: encryptedCreditLimit,
            encryptedMembershipLevel: encryptedMembershipLevel,
            encryptedInsuranceType: encryptedInsuranceType,
            encryptedInsuredPerson: encryptedInsuredPerson,
            encryptedWalletAddress: encryptedWalletAddress,
            encryptedNetworkType: encryptedNetworkType,
            encryptedServer: encryptedServer,
            encryptedPort: encryptedPort
        )
        context.insert(account)
        try context.save()
        loadAccounts()
    }

    // MARK: - 编辑

    /// 使用表单数据更新一条已有记录
    func updateAccount(id: UUID, formData: AccountFormData) throws {
        guard let context = modelContext else {
            errorMessage = "数据库未初始化"
            return
        }

        let descriptor = FetchDescriptor<Account>(
            predicate: #Predicate { $0.id == id }
        )
        let results = try context.fetch(descriptor)
        guard let account = results.first else {
            errorMessage = "未找到该账户"
            return
        }

        account.category = formData.category.rawValue
        account.encryptedName = try securityService.encryptString(formData.name)
        account.encryptedUsername = try securityService.encryptString(formData.username)
        account.encryptedPassword = try securityService.encryptString(formData.password)
        account.encryptedURL = try encryptOpt(formData.url)
        account.encryptedNotes = try encryptOpt(formData.notes)
        account.encryptedBankName = try encryptOpt(formData.bankName)
        account.encryptedCardNumber = try encryptOpt(formData.cardNumber)
        account.encryptedCardholderName = try encryptOpt(formData.cardholderName)
        account.encryptedCardType = try securityService.encryptString(formData.cardType.rawValue)
        account.encryptedBranch = try encryptOpt(formData.branch)
        account.encryptedPhone = try encryptOpt(formData.phone)
        account.encryptedCVV = try encryptOpt(formData.cvv)
        account.encryptedExpiryDate = try encryptOpt(formData.expiryDate)
        account.encryptedBillingDay = try encryptOpt(formData.billingDay)
        account.encryptedRepaymentDay = try encryptOpt(formData.repaymentDay)
        account.encryptedCreditLimit = try encryptOpt(formData.creditLimit)
        account.encryptedFullName = try encryptOpt(formData.fullName)
        account.encryptedDocumentNumber = try encryptOpt(formData.documentNumber)
        account.encryptedIssuingAuthority = try encryptOpt(formData.issuingAuthority)
        account.encryptedSSID = try encryptOpt(formData.ssid)
        account.encryptedSecurityType = try encryptOpt(formData.securityType)
        account.encryptedMembershipLevel = try encryptOpt(formData.membershipLevel)
        account.encryptedInsuranceType = try encryptOpt(formData.insuranceType)
        account.encryptedInsuredPerson = try encryptOpt(formData.insuredPerson)
        account.encryptedWalletAddress = try encryptOpt(formData.walletAddress)
        account.encryptedNetworkType = try encryptOpt(formData.networkType)
        account.encryptedServer = try encryptOpt(formData.server)
        account.encryptedPort = try encryptOpt(formData.port)

        account.modifiedAt = Date()
        try context.save()
        loadAccounts()
    }

    // MARK: - 删除

    /// 删除一条账户记录
    func deleteAccount(id: UUID) throws {
        guard let context = modelContext else {
            errorMessage = "数据库未初始化"
            return
        }

        let descriptor = FetchDescriptor<Account>(
            predicate: #Predicate { $0.id == id }
        )
        let results = try context.fetch(descriptor)
        for account in results {
            context.delete(account)
        }
        try context.save()
        loadAccounts()
    }

    // MARK: - 剪贴板

    /// 复制文本到剪贴板，并在指定秒数后自动清空
    /// - Parameters:
    ///   - text: 要复制的文本
    ///   - autoClearAfter: 自动清空延迟秒数（默认 30 秒）
    func copyToClipboard(_ text: String, autoClearAfter seconds: TimeInterval = 30) {
        UIPasteboard.general.string = text

        // 30 秒后若剪贴板内容仍是此文本则清空
        DispatchQueue.main.asyncAfter(deadline: .now() + seconds) { [text] in
            if UIPasteboard.general.string == text {
                UIPasteboard.general.string = ""
            }
        }
    }
}
