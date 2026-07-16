//
//  AccountEditView.swift
//  KeyVault
//
//  新增 / 编辑账户表单页面
//  支持分类切换：通用凭证 / 银行账户
//

import SwiftUI

/// 编辑模式：新增或编辑已有账户
enum EditMode: Equatable {
    case add
    case edit(AccountDisplay)

    var title: String {
        switch self {
        case .add: return "新增账户"
        case .edit: return "编辑账户"
        }
    }

    var saveButtonTitle: String {
        switch self {
        case .add: return "保存"
        case .edit: return "更新"
        }
    }

    static func == (lhs: EditMode, rhs: EditMode) -> Bool {
        switch (lhs, rhs) {
        case (.add, .add): return true
        case (.edit(let a), .edit(let b)): return a.id == b.id
        default: return false
        }
    }
}

struct AccountEditView: View {

    let mode: EditMode
    let viewModel: AccountViewModel

    @Environment(\.dismiss) private var dismiss

    @State private var formData = AccountFormData()

    @State private var showPassword = false
    @State private var isSaving = false
    @State private var errorMessage: String?
    @State private var showGeneratedPassword = false

    // 银行字段显示状态
    @State private var showCVV = false
    @State private var showCardNumber = false

    var body: some View {
        NavigationStack {
            Form {
                // MARK: 分类选择
                Section {
                    Picker(selection: $formData.category) {
                        ForEach(VaultCategory.allCases, id: \.self) { cat in
                            Label(cat.rawValue, systemImage: cat.iconName)
                                .tag(cat)
                        }
                    } label: {
                        Label("类型", systemImage: "folder")
                            .foregroundColor(.purple)
                    }
                    .pickerStyle(.menu)
                } header: {
                    Text("分类")
                }

                // MARK: 分类专属字段
                switch formData.category {
                case .general:
                    generalCredentialFields
                case .bankAccount:
                    bankAccountFields
                }

                // MARK: 通用密码字段
                Section {
                    HStack {
                        Image(systemName: "key.fill")
                            .foregroundColor(.orange)

                        if showPassword {
                            TextField(
                                formData.category == .bankAccount ? "ATM/查询密码" : "密码 *",
                                text: $formData.password
                            )
                            .textContentType(.password)
                        } else {
                            SecureField(
                                formData.category == .bankAccount ? "ATM/查询密码" : "密码 *",
                                text: $formData.password
                            )
                            .textContentType(.password)
                        }

                        Button {
                            showPassword.toggle()
                        } label: {
                            Image(systemName: showPassword ? "eye.slash" : "eye")
                                .foregroundColor(.secondary)
                        }

                        // 密码生成器（仅通用凭证显示）
                        if formData.category == .general {
                            Button {
                                generatePassword()
                                showPassword = true
                            } label: {
                                Image(systemName: "wand.and.stars")
                                    .foregroundColor(.purple)
                            }
                        }
                    }

                    if showGeneratedPassword && !formData.password.isEmpty {
                        HStack {
                            Image(systemName: "sparkles")
                                .foregroundColor(.purple)
                            Text("已生成随机密码")
                                .font(.caption)
                                .foregroundColor(.purple)
                            Spacer()
                            Button {
                                viewModel.copyToClipboard(formData.password)
                            } label: {
                                Text("复制")
                                    .font(.caption)
                                    .foregroundColor(.purple)
                            }
                        }
                    }
                } header: {
                    Text(formData.category == .bankAccount ? "密码（可选）" : "密码")
                } footer: {
                    if formData.category == .general {
                        Text("点击 ✨ 按钮可生成高强度随机密码")
                    }
                }

                // MARK: 备注（所有分类共用）
                Section("备注（可选）") {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(alignment: .top) {
                            Image(systemName: "note.text")
                                .foregroundColor(.gray)
                                .padding(.top, 8)
                            TextField("备注", text: $formData.notes, axis: .vertical)
                                .lineLimit(3...6)
                        }
                    }
                }

                // MARK: 错误提示
                if let error = errorMessage {
                    Section {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.red)
                            Text(error)
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                    }
                }
            }
            .navigationTitle(mode.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        save()
                    } label: {
                        if isSaving {
                            ProgressView()
                        } else {
                            Text(mode.saveButtonTitle)
                                .fontWeight(.semibold)
                        }
                    }
                    .disabled(!formData.isValid || isSaving)
                }
            }
            .onAppear {
                if case .edit(let account) = mode {
                    formData = AccountFormData(from: account)
                }
            }
        }
    }

    // MARK: - 通用凭证字段

    private var generalCredentialFields: some View {
        Group {
            Section("基本信息") {
                HStack {
                    Image(systemName: "tag.fill")
                        .foregroundColor(.purple)
                    TextField("名称（如网站/App 名称）*", text: $formData.name)
                        .textContentType(.name)
                }

                HStack {
                    Image(systemName: "person.fill")
                        .foregroundColor(.purple)
                    TextField("账号/用户名 *", text: $formData.username)
                        .textContentType(.username)
                        .autocapitalization(.none)
                }
            }

            Section("可选信息") {
                HStack {
                    Image(systemName: "link")
                        .foregroundColor(.purple)
                    TextField("网址（可选）", text: $formData.url)
                        .textContentType(.URL)
                        .keyboardType(.URL)
                        .autocapitalization(.none)
                }
            }
        }
    }

    // MARK: - 银行账户字段

    private var bankAccountFields: some View {
        Group {
            Section("银行信息") {
                HStack {
                    Image(systemName: "building.columns.fill")
                        .foregroundColor(.blue)
                    TextField("银行名称 *", text: $formData.bankName)
                }

                HStack {
                    Image(systemName: "creditcard.fill")
                        .foregroundColor(.blue)

                    if showCardNumber {
                        TextField("银行卡号 *", text: $formData.cardNumber)
                            .keyboardType(.numberPad)
                    } else {
                        SecureField("银行卡号 *", text: $formData.cardNumber)
                            .keyboardType(.numberPad)
                    }

                    Button {
                        showCardNumber.toggle()
                    } label: {
                        Image(systemName: showCardNumber ? "eye.slash" : "eye")
                            .foregroundColor(.secondary)
                    }
                }

                HStack {
                    Image(systemName: "person.text.rectangle.fill")
                        .foregroundColor(.blue)
                    TextField("户名", text: $formData.cardholderName)
                }

                Picker(selection: $formData.cardType) {
                    ForEach(CardType.allCases, id: \.self) { type in
                        Text(type.rawValue).tag(type)
                    }
                } label: {
                    Label("卡类型", systemImage: "wallet.pass")
                        .foregroundColor(.blue)
                }
            }

            Section("安全信息") {
                HStack {
                    Image(systemName: "number.square.fill")
                        .foregroundColor(.orange)

                    if showCVV {
                        TextField("CVV 安全码", text: $formData.cvv)
                            .keyboardType(.numberPad)
                    } else {
                        SecureField("CVV 安全码", text: $formData.cvv)
                            .keyboardType(.numberPad)
                    }

                    Button {
                        showCVV.toggle()
                    } label: {
                        Image(systemName: showCVV ? "eye.slash" : "eye")
                            .foregroundColor(.secondary)
                    }
                }

                HStack {
                    Image(systemName: "calendar")
                        .foregroundColor(.orange)
                    TextField("有效期（如 12/28）", text: $formData.expiryDate)
                        .keyboardType(.numbersAndPunctuation)
                }
            }

            Section("其他信息（可选）") {
                HStack {
                    Image(systemName: "mappin.and.ellipse")
                        .foregroundColor(.gray)
                    TextField("开户行", text: $formData.branch)
                }

                HStack {
                    Image(systemName: "phone.fill")
                        .foregroundColor(.gray)
                    TextField("预留手机号", text: $formData.phone)
                        .keyboardType(.phonePad)
                }
            }
        }
    }

    // MARK: - 保存

    private func save() {
        isSaving = true
        errorMessage = nil

        // 如果银行账户未填 name，自动拼接银行名称+卡类型
        if formData.category == .bankAccount && formData.name.isEmpty {
            let typeStr = formData.cardType.rawValue
            if !formData.bankName.isEmpty {
                formData.name = "\(formData.bankName) \(typeStr)"
            }
        }

        do {
            switch mode {
            case .add:
                try viewModel.saveAccount(formData: formData)
            case .edit(let account):
                try viewModel.updateAccount(id: account.id, formData: formData)
            }

            isSaving = false
            dismiss()
        } catch {
            errorMessage = "保存失败：\(error.localizedDescription)"
            isSaving = false
        }
    }

    // MARK: - 密码生成器

    private func generatePassword() {
        let length = 20
        let uppercase = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
        let lowercase = "abcdefghijklmnopqrstuvwxyz"
        let digits = "0123456789"
        let symbols = "!@#$%^&*()-_=+[]{}|;:,.<>?"
        let allChars = uppercase + lowercase + digits + symbols

        var passwordChars: [Character] = [
            uppercase.randomElement()!,
            lowercase.randomElement()!,
            digits.randomElement()!,
            symbols.randomElement()!
        ]

        for _ in 4..<length {
            passwordChars.append(allChars.randomElement()!)
        }

        passwordChars.shuffle()
        let generatedPassword = String(passwordChars)

        withAnimation {
            formData.password = generatedPassword
            showGeneratedPassword = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            withAnimation {
                showGeneratedPassword = false
            }
        }
    }
}

#Preview("新增通用凭证") {
    AccountEditView(mode: .add, viewModel: AccountViewModel())
}

#Preview("新增银行账户") {
    AccountEditView(mode: .add, viewModel: AccountViewModel())
}
