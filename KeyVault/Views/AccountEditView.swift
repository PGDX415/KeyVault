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
                categoryFields

                // MARK: 密码字段（除证件类和钱包外都显示）
                if formData.category != .idCard && formData.category != .driversLicense &&
                   formData.category != .passport && formData.category != .socialSecurity &&
                   formData.category != .cryptoWallet {
                    let isBank = formData.category == .bankAccount || formData.category == .creditCard
                    Section {
                        passwordField(isOptional: isBank, placeholder: isBank ? "ATM/查询密码" : "密码 *")
                    } header: {
                        Text(isBank ? "密码（可选）" : "密码")
                    } footer: {
                        if !isBank {
                            Text("点击 ✨ 按钮可生成高强度随机密码")
                        }
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

    // MARK: - 密码输入行

    private func passwordField(isOptional: Bool, placeholder: String) -> some View {
        Group {
            HStack {
                Image(systemName: "key.fill").foregroundColor(.orange)
                if showPassword {
                    TextField(placeholder, text: $formData.password).textContentType(.password)
                } else {
                    SecureField(placeholder, text: $formData.password).textContentType(.password)
                }
                Button { showPassword.toggle() } label: {
                    Image(systemName: showPassword ? "eye.slash" : "eye").foregroundColor(.secondary)
                }
                if !isOptional {
                    Button { generatePassword(); showPassword = true } label: {
                        Image(systemName: "wand.and.stars").foregroundColor(.purple)
                    }
                }
            }
            if showGeneratedPassword && !formData.password.isEmpty {
                HStack {
                    Image(systemName: "sparkles").foregroundColor(.purple)
                    Text("已生成随机密码").font(.caption).foregroundColor(.purple)
                    Spacer()
                    Button("复制") { viewModel.copyToClipboard(formData.password) }
                        .font(.caption).foregroundColor(.purple)
                }
            }
        }
    }

    // MARK: - 通用输入组件

    private func fieldRow(icon: String, color: Color, placeholder: String, text: Binding<String>, isSecure: Bool = false) -> some View {
        HStack {
            Image(systemName: icon).foregroundColor(color).frame(width: 24)
            if isSecure {
                SecureField(placeholder, text: text)
            } else {
                TextField(placeholder, text: text)
            }
        }
    }

    // MARK: - 分类字段

    @ViewBuilder
    private var categoryFields: some View {
        switch formData.category {
        // ── 通用凭证 / 登陆密码 / 互联网账户 ──
        case .general, .loginPassword, .internetAccount:
            Section("基本信息") {
                fieldRow(icon: "tag.fill", color: .purple, placeholder: "名称 *", text: $formData.name)
                fieldRow(icon: "person.fill", color: .purple, placeholder: "账号/用户名 *", text: $formData.username)
            }
            Section("可选信息") {
                fieldRow(icon: "link", color: .purple, placeholder: "网址", text: $formData.url)
            }

        // ── 电子邮件账户 ──
        case .emailAccount:
            Section("基本信息") {
                fieldRow(icon: "tag.fill", color: .blue, placeholder: "名称 *", text: $formData.name)
                fieldRow(icon: "envelope.fill", color: .blue, placeholder: "邮箱地址 *", text: $formData.username)
            }
            Section("服务器设置（可选）") {
                fieldRow(icon: "server.rack", color: .gray, placeholder: "邮件服务器", text: $formData.server)
                fieldRow(icon: "number", color: .gray, placeholder: "端口", text: $formData.port)
            }

        // ── 银行账户 ──
        case .bankAccount:
            Section("银行信息") {
                fieldRow(icon: "building.columns.fill", color: .blue, placeholder: "银行名称 *", text: $formData.bankName)
                fieldRow(icon: "creditcard.fill", color: .blue, placeholder: "银行卡号 *", text: $formData.cardNumber, isSecure: !showCardNumber)
                HStack { Button { showCardNumber.toggle() } label: { Image(systemName: showCardNumber ? "eye.slash" : "eye").foregroundColor(.secondary) }.buttonStyle(.plain); Spacer() }.listRowBackground(Color.clear)
                fieldRow(icon: "person.text.rectangle.fill", color: .blue, placeholder: "户名", text: $formData.cardholderName)
                Picker(selection: $formData.cardType) {
                    ForEach(CardType.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                } label: { Label("卡类型", systemImage: "wallet.pass").foregroundColor(.blue) }
            }
            Section("安全信息") {
                fieldRow(icon: "number.square.fill", color: .orange, placeholder: "CVV 安全码", text: $formData.cvv, isSecure: !showCVV)
                HStack { Button { showCVV.toggle() } label: { Image(systemName: showCVV ? "eye.slash" : "eye").foregroundColor(.secondary) }.buttonStyle(.plain); Spacer() }.listRowBackground(Color.clear)
                fieldRow(icon: "calendar", color: .orange, placeholder: "有效期（如 12/28）", text: $formData.expiryDate)
            }
            Section("其他（可选）") {
                fieldRow(icon: "mappin.and.ellipse", color: .gray, placeholder: "开户行", text: $formData.branch)
                fieldRow(icon: "phone.fill", color: .gray, placeholder: "预留手机号", text: $formData.phone)
            }

        // ── 信用卡 ──
        case .creditCard:
            Section("卡片信息") {
                fieldRow(icon: "building.columns.fill", color: .red, placeholder: "发卡银行 *", text: $formData.bankName)
                fieldRow(icon: "creditcard.fill", color: .red, placeholder: "卡号 *", text: $formData.cardNumber, isSecure: !showCardNumber)
                HStack { Button { showCardNumber.toggle() } label: { Image(systemName: showCardNumber ? "eye.slash" : "eye").foregroundColor(.secondary) }.buttonStyle(.plain); Spacer() }.listRowBackground(Color.clear)
                fieldRow(icon: "person.text.rectangle.fill", color: .red, placeholder: "持卡人姓名", text: $formData.cardholderName)
                fieldRow(icon: "calendar", color: .orange, placeholder: "有效期（MM/YY）*", text: $formData.expiryDate)
                fieldRow(icon: "number.square.fill", color: .orange, placeholder: "CVV", text: $formData.cvv, isSecure: !showCVV)
                HStack { Button { showCVV.toggle() } label: { Image(systemName: showCVV ? "eye.slash" : "eye").foregroundColor(.secondary) }.buttonStyle(.plain); Spacer() }.listRowBackground(Color.clear)
            }
            Section("账单信息（可选）") {
                fieldRow(icon: "calendar.badge.clock", color: .gray, placeholder: "账单日", text: $formData.billingDay)
                fieldRow(icon: "calendar.badge.checkmark", color: .gray, placeholder: "还款日", text: $formData.repaymentDay)
                fieldRow(icon: "banknote", color: .gray, placeholder: "信用额度", text: $formData.creditLimit)
                fieldRow(icon: "phone.fill", color: .gray, placeholder: "银行客服电话", text: $formData.phone)
            }

        // ── 会员 ──
        case .membership:
            Section("会员信息") {
                fieldRow(icon: "tag.fill", color: .orange, placeholder: "商户/品牌名称 *", text: $formData.name)
                fieldRow(icon: "person.fill", color: .orange, placeholder: "会员号/卡号 *", text: $formData.documentNumber)
                fieldRow(icon: "star.fill", color: .orange, placeholder: "会员等级", text: $formData.membershipLevel)
                fieldRow(icon: "calendar", color: .gray, placeholder: "有效期", text: $formData.expiryDate)
            }
            Section("可选信息") {
                fieldRow(icon: "link", color: .gray, placeholder: "官网/APP 链接", text: $formData.url)
            }

        // ── 社保 ──
        case .socialSecurity:
            Section("社保信息") {
                fieldRow(icon: "tag.fill", color: .teal, placeholder: "名称 *", text: $formData.name)
                fieldRow(icon: "person.fill", color: .teal, placeholder: "姓名 *", text: $formData.fullName)
                fieldRow(icon: "number.square.fill", color: .teal, placeholder: "社保号码 *", text: $formData.documentNumber)
                fieldRow(icon: "building.2.fill", color: .gray, placeholder: "发卡机构", text: $formData.issuingAuthority)
                fieldRow(icon: "calendar", color: .gray, placeholder: "有效期", text: $formData.expiryDate)
            }

        // ── 驾照 / 身份证 / 护照 ──
        case .driversLicense, .idCard, .passport:
            let c = formData.category.color
            Section("证件信息") {
                fieldRow(icon: "tag.fill", color: c, placeholder: "名称 *", text: $formData.name)
                fieldRow(icon: "person.fill", color: c, placeholder: "姓名 *", text: $formData.fullName)
                let docLabel = formData.category == .idCard ? "身份证号 *"
                    : formData.category == .passport ? "护照号 *" : "驾照号 *"
                fieldRow(icon: "number.square.fill", color: c, placeholder: docLabel, text: $formData.documentNumber)
                let authLabel = formData.category == .idCard ? "签发机关"
                    : formData.category == .passport ? "签发国家/机关" : "发证机关"
                fieldRow(icon: "building.2.fill", color: .gray, placeholder: authLabel, text: $formData.issuingAuthority)
                fieldRow(icon: "calendar", color: .gray, placeholder: "有效期", text: $formData.expiryDate)
            }

        // ── Wi-Fi 路由器 ──
        case .wifiRouter:
            Section("Wi-Fi 信息") {
                fieldRow(icon: "tag.fill", color: .blue, placeholder: "名称 *", text: $formData.name)
                fieldRow(icon: "wifi", color: .blue, placeholder: "SSID（Wi-Fi 名称）*", text: $formData.ssid)
                fieldRow(icon: "lock.shield.fill", color: .gray, placeholder: "安全类型（WPA2/WPA3/WEP）", text: $formData.securityType)
            }

        // ── 保险 ──
        case .insurance:
            Section("保险信息") {
                fieldRow(icon: "tag.fill", color: .mint, placeholder: "名称（如险种名称）*", text: $formData.name)
                fieldRow(icon: "building.columns.fill", color: .mint, placeholder: "保险公司", text: $formData.bankName)
                fieldRow(icon: "umbrella.fill", color: .mint, placeholder: "险种", text: $formData.insuranceType)
                fieldRow(icon: "person.fill", color: .mint, placeholder: "被保人", text: $formData.insuredPerson)
                fieldRow(icon: "doc.text.fill", color: .gray, placeholder: "保单号", text: $formData.documentNumber)
                fieldRow(icon: "calendar", color: .gray, placeholder: "有效期", text: $formData.expiryDate)
                fieldRow(icon: "phone.fill", color: .gray, placeholder: "客服电话", text: $formData.phone)
            }

        // ── 网路服务提供商 ──
        case .isp:
            Section("服务信息") {
                fieldRow(icon: "tag.fill", color: .gray, placeholder: "服务商名称 *", text: $formData.name)
                fieldRow(icon: "person.fill", color: .gray, placeholder: "账号 *", text: $formData.username)
                fieldRow(icon: "doc.text.fill", color: .gray, placeholder: "套餐", text: $formData.networkType)
                fieldRow(icon: "phone.fill", color: .gray, placeholder: "客服电话", text: $formData.phone)
            }

        // ── 加密币钱包 ──
        case .cryptoWallet:
            Section("钱包信息") {
                fieldRow(icon: "tag.fill", color: .orange, placeholder: "名称 *", text: $formData.name)
                fieldRow(icon: "bitcoinsign.circle", color: .orange, placeholder: "钱包地址 *", text: $formData.walletAddress)
                fieldRow(icon: "circle.hexagongrid", color: .gray, placeholder: "网络类型（如 ERC20/TRC20）", text: $formData.networkType)
            }
        }
    }

    // MARK: - 保存

    private func save() {
        isSaving = true
        errorMessage = nil

        // 自动填充名称（如果用户未填）
        if formData.name.isEmpty {
            switch formData.category {
            case .bankAccount:
                let t = formData.cardType.rawValue
                if !formData.bankName.isEmpty { formData.name = "\(formData.bankName) \(t)" }
            case .creditCard:
                if !formData.bankName.isEmpty { formData.name = "\(formData.bankName) 信用卡" }
            case .wifiRouter:
                if !formData.ssid.isEmpty { formData.name = formData.ssid }
            case .emailAccount:
                if !formData.username.isEmpty { formData.name = formData.username }
            default: break
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
