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
                    url: try account.encryptedURL.map { try securityService.decryptString($0) } ?? "",
                    notes: try account.encryptedNotes.map { try securityService.decryptString($0) } ?? "",
                    // 银行账户字段
                    bankName: try account.encryptedBankName.map { try securityService.decryptString($0) } ?? "",
                    cardNumber: try account.encryptedCardNumber.map { try securityService.decryptString($0) } ?? "",
                    cardholderName: try account.encryptedCardholderName.map { try securityService.decryptString($0) } ?? "",
                    cardType: (try account.encryptedCardType.map { raw in
                        CardType(rawValue: try securityService.decryptString(raw)) ?? .debit
                    }) ?? .debit,
                    branch: try account.encryptedBranch.map { try securityService.decryptString($0) } ?? "",
                    phone: try account.encryptedPhone.map { try securityService.decryptString($0) } ?? "",
                    cvv: try account.encryptedCVV.map { try securityService.decryptString($0) } ?? "",
                    expiryDate: try account.encryptedExpiryDate.map { try securityService.decryptString($0) } ?? "",
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
        let encryptedURL = formData.url.isEmpty ? nil : try securityService.encryptString(formData.url)
        let encryptedNotes = formData.notes.isEmpty ? nil : try securityService.encryptString(formData.notes)

        // 银行专属字段
        let encryptedBankName = formData.bankName.isEmpty ? nil : try securityService.encryptString(formData.bankName)
        let encryptedCardNumber = formData.cardNumber.isEmpty ? nil : try securityService.encryptString(formData.cardNumber)
        let encryptedCardholderName = formData.cardholderName.isEmpty ? nil : try securityService.encryptString(formData.cardholderName)
        let encryptedCardType = try securityService.encryptString(formData.cardType.rawValue)
        let encryptedBranch = formData.branch.isEmpty ? nil : try securityService.encryptString(formData.branch)
        let encryptedPhone = formData.phone.isEmpty ? nil : try securityService.encryptString(formData.phone)
        let encryptedCVV = formData.cvv.isEmpty ? nil : try securityService.encryptString(formData.cvv)
        let encryptedExpiryDate = formData.expiryDate.isEmpty ? nil : try securityService.encryptString(formData.expiryDate)

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
            encryptedExpiryDate: encryptedExpiryDate
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
        account.encryptedURL = formData.url.isEmpty ? nil : try securityService.encryptString(formData.url)
        account.encryptedNotes = formData.notes.isEmpty ? nil : try securityService.encryptString(formData.notes)

        // 银行专属字段
        account.encryptedBankName = formData.bankName.isEmpty ? nil : try securityService.encryptString(formData.bankName)
        account.encryptedCardNumber = formData.cardNumber.isEmpty ? nil : try securityService.encryptString(formData.cardNumber)
        account.encryptedCardholderName = formData.cardholderName.isEmpty ? nil : try securityService.encryptString(formData.cardholderName)
        account.encryptedCardType = try securityService.encryptString(formData.cardType.rawValue)
        account.encryptedBranch = formData.branch.isEmpty ? nil : try securityService.encryptString(formData.branch)
        account.encryptedPhone = formData.phone.isEmpty ? nil : try securityService.encryptString(formData.phone)
        account.encryptedCVV = formData.cvv.isEmpty ? nil : try securityService.encryptString(formData.cvv)
        account.encryptedExpiryDate = formData.expiryDate.isEmpty ? nil : try securityService.encryptString(formData.expiryDate)

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
