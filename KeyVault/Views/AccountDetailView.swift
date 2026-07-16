//
//  AccountDetailView.swift
//  KeyVault
//
//  账户详情页面：根据分类展示不同字段
//  通用凭证：账号、密码、网址
//  银行账户：银行卡号、户名、CVV、有效期等
//

import SwiftUI

struct AccountDetailView: View {

    let account: AccountDisplay
    let viewModel: AccountViewModel

    @State private var isPasswordVisible = false
    @State private var isCardNumberVisible = false
    @State private var isCVVVisible = false
    @State private var copyFeedback: String?
    @State private var showEditSheet = false

    private var accentColor: Color {
        account.category.color
    }

    private var gradientColors: [Color] {
        [account.category.color, account.category.color.opacity(0.7)]
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                headerSection

                Divider()

                // 分类图标
                categoryBadge

                // 根据分类显示不同字段
                categoryDetailSection

                Divider()

                metaSection
            }
            .padding(24)
        }
        .background(Color(.systemBackground))
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showEditSheet = true
                } label: {
                    Text("编辑")
                }
            }
        }
        .sheet(isPresented: $showEditSheet) {
            AccountEditView(mode: .edit(account), viewModel: viewModel)
        }
        .overlay(alignment: .bottom) {
            if let feedback = copyFeedback {
                Text(feedback)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(.ultraThinMaterial)
                    .cornerRadius(20)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .padding(.bottom, 20)
            }
        }
        .animation(.easeInOut, value: copyFeedback)
        .environment(\.locale, Locale(identifier: "zh_CN"))
    }

    // MARK: - 头部区域

    private var headerSection: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: gradientColors,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 56, height: 56)

                Image(systemName: account.category.iconName)
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(account.name)
                    .font(.title2)
                    .fontWeight(.bold)

                if !account.url.isEmpty {
                    Text(account.url)
                        .font(.subheadline)
                        .foregroundColor(accentColor)
                        .lineLimit(1)
                }
            }

            Spacer()
        }
    }

    // MARK: - 分类徽章

    private var categoryBadge: some View {
        HStack(spacing: 6) {
            Image(systemName: account.category.iconName)
                .font(.caption)
            Text(account.category.rawValue)
                .font(.caption)
                .fontWeight(.medium)
        }
        .foregroundColor(accentColor)
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
        .background(accentColor.opacity(0.1))
        .cornerRadius(6)
    }

    // MARK: - 分类详情

    @ViewBuilder
    private var categoryDetailSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            switch account.category {
            // ── 通用 / 登陆密码 / 互联网账户 ──
            case .general, .loginPassword, .internetAccount:
                if !account.username.isEmpty {
                    maskableInfoRow(icon: "person.fill", label: "账号", value: account.username, isVisible: true, iconColor: accentColor, onCopy: { copyToClipboard(account.username, label: "账号已复制") })
                }
                if !account.password.isEmpty {
                    maskableInfoRow(icon: "key.fill", label: "密码", value: account.password, isVisible: isPasswordVisible, iconColor: .orange, onToggle: { isPasswordVisible.toggle() }) { copyToClipboard(account.password, label: "密码已复制") }
                }
                if !account.url.isEmpty {
                    infoRow(icon: "link", label: "网址", value: account.url, iconColor: accentColor) { copyToClipboard(account.url, label: "网址已复制") }
                }

            // ── 电子邮件账户 ──
            case .emailAccount:
                if !account.username.isEmpty {
                    maskableInfoRow(icon: "envelope.fill", label: "邮箱地址", value: account.username, isVisible: true, iconColor: .blue, onCopy: { copyToClipboard(account.username, label: "邮箱已复制") })
                }
                if !account.password.isEmpty {
                    maskableInfoRow(icon: "key.fill", label: "密码", value: account.password, isVisible: isPasswordVisible, iconColor: .orange, onToggle: { isPasswordVisible.toggle() }) { copyToClipboard(account.password, label: "密码已复制") }
                }
                if !account.server.isEmpty { labelValueRow(icon: "server.rack", label: "服务器", value: account.server, iconColor: .gray) }
                if !account.port.isEmpty { labelValueRow(icon: "number", label: "端口", value: account.port, iconColor: .gray) }

            // ── 银行账户 ──
            case .bankAccount:
                if !account.bankName.isEmpty { labelValueRow(icon: "building.columns.fill", label: "发卡银行", value: account.bankName, iconColor: .blue) }
                labelValueRow(icon: "wallet.pass", label: "卡类型", value: account.cardType.rawValue, iconColor: .blue)
                if !account.cardNumber.isEmpty {
                    maskableInfoRow(icon: "creditcard.fill", label: "银行卡号", value: account.cardNumber, isVisible: isCardNumberVisible, iconColor: .blue, onToggle: { isCardNumberVisible.toggle() }) { copyToClipboard(account.cardNumber, label: "卡号已复制") }
                }
                if !account.cardholderName.isEmpty {
                    maskableInfoRow(icon: "person.text.rectangle.fill", label: "户名", value: account.cardholderName, isVisible: true, iconColor: .blue, onCopy: { copyToClipboard(account.cardholderName, label: "户名已复制") })
                }
                if !account.cvv.isEmpty {
                    maskableInfoRow(icon: "number.square.fill", label: "CVV 安全码", value: account.cvv, isVisible: isCVVVisible, iconColor: .orange, onToggle: { isCVVVisible.toggle() }) { copyToClipboard(account.cvv, label: "CVV 已复制") }
                }
                if !account.expiryDate.isEmpty {
                    infoRow(icon: "calendar", label: "有效期", value: account.expiryDate, iconColor: .orange) { copyToClipboard(account.expiryDate, label: "有效期已复制") }
                }
                if !account.password.isEmpty {
                    maskableInfoRow(icon: "key.fill", label: "ATM/查询密码", value: account.password, isVisible: isPasswordVisible, iconColor: .orange, onToggle: { isPasswordVisible.toggle() }) { copyToClipboard(account.password, label: "密码已复制") }
                }
                if !account.branch.isEmpty { labelValueRow(icon: "mappin.and.ellipse", label: "开户行", value: account.branch, iconColor: .gray) }
                if !account.phone.isEmpty {
                    infoRow(icon: "phone.fill", label: "预留手机号", value: account.phone, iconColor: .gray) { copyToClipboard(account.phone, label: "手机号已复制") }
                }

            // ── 信用卡 ──
            case .creditCard:
                if !account.bankName.isEmpty { labelValueRow(icon: "building.columns.fill", label: "发卡银行", value: account.bankName, iconColor: .red) }
                if !account.cardNumber.isEmpty {
                    maskableInfoRow(icon: "creditcard.fill", label: "卡号", value: account.cardNumber, isVisible: isCardNumberVisible, iconColor: .red, onToggle: { isCardNumberVisible.toggle() }) { copyToClipboard(account.cardNumber, label: "卡号已复制") }
                }
                if !account.cardholderName.isEmpty { labelValueRow(icon: "person.fill", label: "持卡人", value: account.cardholderName, iconColor: .red) }
                if !account.expiryDate.isEmpty { infoRow(icon: "calendar", label: "有效期", value: account.expiryDate, iconColor: .orange) { copyToClipboard(account.expiryDate, label: "有效期已复制") } }
                if !account.cvv.isEmpty {
                    maskableInfoRow(icon: "number.square.fill", label: "CVV", value: account.cvv, isVisible: isCVVVisible, iconColor: .orange, onToggle: { isCVVVisible.toggle() }) { copyToClipboard(account.cvv, label: "CVV 已复制") }
                }
                if !account.password.isEmpty {
                    maskableInfoRow(icon: "key.fill", label: "查询密码", value: account.password, isVisible: isPasswordVisible, iconColor: .orange, onToggle: { isPasswordVisible.toggle() }) { copyToClipboard(account.password, label: "密码已复制") }
                }
                if !account.billingDay.isEmpty { labelValueRow(icon: "calendar.badge.clock", label: "账单日", value: account.billingDay, iconColor: .gray) }
                if !account.repaymentDay.isEmpty { labelValueRow(icon: "calendar.badge.checkmark", label: "还款日", value: account.repaymentDay, iconColor: .gray) }
                if !account.creditLimit.isEmpty { labelValueRow(icon: "banknote", label: "额度", value: account.creditLimit, iconColor: .gray) }
                if !account.phone.isEmpty { infoRow(icon: "phone.fill", label: "客服电话", value: account.phone, iconColor: .gray) { copyToClipboard(account.phone, label: "电话已复制") } }

            // ── 会员 ──
            case .membership:
                if !account.documentNumber.isEmpty {
                    maskableInfoRow(icon: "person.fill", label: "会员号", value: account.documentNumber, isVisible: true, iconColor: .orange, onCopy: { copyToClipboard(account.documentNumber, label: "会员号已复制") })
                }
                if !account.membershipLevel.isEmpty { labelValueRow(icon: "star.fill", label: "等级", value: account.membershipLevel, iconColor: .orange) }
                if !account.password.isEmpty {
                    maskableInfoRow(icon: "key.fill", label: "密码", value: account.password, isVisible: isPasswordVisible, iconColor: .orange, onToggle: { isPasswordVisible.toggle() }) { copyToClipboard(account.password, label: "密码已复制") }
                }
                if !account.expiryDate.isEmpty { infoRow(icon: "calendar", label: "有效期", value: account.expiryDate, iconColor: .gray) { copyToClipboard(account.expiryDate, label: "有效期已复制") } }
                if !account.url.isEmpty { infoRow(icon: "link", label: "官网", value: account.url, iconColor: accentColor) { copyToClipboard(account.url, label: "网址已复制") } }

            // ── 社保 ──
            case .socialSecurity:
                if !account.fullName.isEmpty { labelValueRow(icon: "person.fill", label: "姓名", value: account.fullName, iconColor: .teal) }
                if !account.documentNumber.isEmpty {
                    maskableInfoRow(icon: "number.square.fill", label: "社保号码", value: account.documentNumber, isVisible: true, iconColor: .teal, onCopy: { copyToClipboard(account.documentNumber, label: "社保号已复制") })
                }
                if !account.issuingAuthority.isEmpty { labelValueRow(icon: "building.2.fill", label: "发卡机构", value: account.issuingAuthority, iconColor: .gray) }
                if !account.expiryDate.isEmpty { infoRow(icon: "calendar", label: "有效期", value: account.expiryDate, iconColor: .gray) { copyToClipboard(account.expiryDate, label: "有效期已复制") } }

            // ── 驾照 / 身份证 / 护照 ──
            case .driversLicense, .idCard, .passport:
                let c = account.category.color
                if !account.fullName.isEmpty { labelValueRow(icon: "person.fill", label: "姓名", value: account.fullName, iconColor: c) }
                if !account.documentNumber.isEmpty {
                    let docLabel = account.category == .idCard ? "身份证号" : account.category == .passport ? "护照号" : "驾照号"
                    maskableInfoRow(icon: "number.square.fill", label: docLabel, value: account.documentNumber, isVisible: true, iconColor: c, onCopy: { copyToClipboard(account.documentNumber, label: "\(docLabel)已复制") })
                }
                if !account.issuingAuthority.isEmpty { labelValueRow(icon: "building.2.fill", label: "签发机关", value: account.issuingAuthority, iconColor: .gray) }
                if !account.expiryDate.isEmpty { infoRow(icon: "calendar", label: "有效期", value: account.expiryDate, iconColor: .gray) { copyToClipboard(account.expiryDate, label: "有效期已复制") } }

            // ── Wi-Fi 路由器 ──
            case .wifiRouter:
                if !account.ssid.isEmpty { labelValueRow(icon: "wifi", label: "SSID", value: account.ssid, iconColor: .blue) }
                if !account.securityType.isEmpty { labelValueRow(icon: "lock.shield.fill", label: "安全类型", value: account.securityType, iconColor: .gray) }
                if !account.password.isEmpty {
                    maskableInfoRow(icon: "key.fill", label: "密码", value: account.password, isVisible: isPasswordVisible, iconColor: .orange, onToggle: { isPasswordVisible.toggle() }) { copyToClipboard(account.password, label: "密码已复制") }
                }

            // ── 保险 ──
            case .insurance:
                if !account.bankName.isEmpty { labelValueRow(icon: "building.columns.fill", label: "保险公司", value: account.bankName, iconColor: .mint) }
                if !account.insuranceType.isEmpty { labelValueRow(icon: "umbrella.fill", label: "险种", value: account.insuranceType, iconColor: .mint) }
                if !account.insuredPerson.isEmpty { labelValueRow(icon: "person.fill", label: "被保人", value: account.insuredPerson, iconColor: .mint) }
                if !account.documentNumber.isEmpty {
                    maskableInfoRow(icon: "doc.text.fill", label: "保单号", value: account.documentNumber, isVisible: true, iconColor: .gray, onCopy: { copyToClipboard(account.documentNumber, label: "保单号已复制") })
                }
                if !account.expiryDate.isEmpty { infoRow(icon: "calendar", label: "有效期", value: account.expiryDate, iconColor: .gray) { copyToClipboard(account.expiryDate, label: "有效期已复制") } }
                if !account.phone.isEmpty { infoRow(icon: "phone.fill", label: "客服电话", value: account.phone, iconColor: .gray) { copyToClipboard(account.phone, label: "电话已复制") } }

            // ── 网路服务提供商 ──
            case .isp:
                if !account.username.isEmpty {
                    maskableInfoRow(icon: "person.fill", label: "账号", value: account.username, isVisible: true, iconColor: .gray, onCopy: { copyToClipboard(account.username, label: "账号已复制") })
                }
                if !account.password.isEmpty {
                    maskableInfoRow(icon: "key.fill", label: "密码", value: account.password, isVisible: isPasswordVisible, iconColor: .orange, onToggle: { isPasswordVisible.toggle() }) { copyToClipboard(account.password, label: "密码已复制") }
                }
                if !account.networkType.isEmpty { labelValueRow(icon: "doc.text.fill", label: "套餐", value: account.networkType, iconColor: .gray) }
                if !account.phone.isEmpty { infoRow(icon: "phone.fill", label: "客服电话", value: account.phone, iconColor: .gray) { copyToClipboard(account.phone, label: "电话已复制") } }

            // ── 加密币钱包 ──
            case .cryptoWallet:
                if !account.walletAddress.isEmpty {
                    maskableInfoRow(icon: "bitcoinsign.circle", label: "钱包地址", value: account.walletAddress, isVisible: true, iconColor: .orange, onCopy: { copyToClipboard(account.walletAddress, label: "地址已复制") })
                }
                if !account.networkType.isEmpty { labelValueRow(icon: "circle.hexagongrid", label: "网络类型", value: account.networkType, iconColor: .gray) }
                if !account.password.isEmpty {
                    maskableInfoRow(icon: "key.fill", label: "私钥/助记词", value: account.password, isVisible: isPasswordVisible, iconColor: .orange, onToggle: { isPasswordVisible.toggle() }) { copyToClipboard(account.password, label: "私钥已复制") }
                }
            }
        }
    }

    // MARK: - 元信息

    private var metaSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            if !account.notes.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Image(systemName: "note.text")
                            .foregroundColor(.gray)
                            .frame(width: 20)
                        Text("备注")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    Text(account.notes)
                        .font(.body)
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                }
            }

            Divider()

            HStack {
                Image(systemName: "clock")
                    .foregroundColor(.gray)
                    .frame(width: 20)
                Text("创建时间")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Spacer()
                Text(account.createdAt, style: .date)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            HStack {
                Image(systemName: "clock.arrow.circlepath")
                    .foregroundColor(.gray)
                    .frame(width: 20)
                Text("修改时间")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Spacer()
                Text(account.modifiedAt, style: .date)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
    }

    // MARK: - 辅助组件

    /// 不可切换可见性的信息行
    private func infoRow(
        icon: String,
        label: String,
        value: String,
        iconColor: Color,
        onCopy: @escaping () -> Void = {}
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(iconColor)
                    .frame(width: 20)
                Text(label)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Spacer()
                Button(action: onCopy) {
                    Image(systemName: "doc.on.doc")
                        .font(.body)
                        .foregroundColor(accentColor)
                }
            }
            Text(value)
                .font(.body)
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(.systemGray6))
                .cornerRadius(8)
        }
    }

    /// 可切换可见性的信息行（带 eye 按钮 + 复制按钮）
    private func maskableInfoRow(
        icon: String,
        label: String,
        value: String,
        isVisible: Bool,
        iconColor: Color,
        onToggle: (() -> Void)? = nil,
        onCopy: @escaping () -> Void = {}
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(iconColor)
                    .frame(width: 20)
                Text(label)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Spacer()
                HStack(spacing: 12) {
                    if let toggle = onToggle {
                        Button(action: toggle) {
                            Image(systemName: isVisible ? "eye.slash" : "eye")
                                .font(.body)
                                .foregroundColor(accentColor)
                        }
                    }
                    Button(action: onCopy) {
                        Image(systemName: "doc.on.doc")
                            .font(.body)
                            .foregroundColor(accentColor)
                    }
                }
            }

            if isVisible {
                Text(value)
                    .font(.body.monospaced())
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
            } else {
                Text(String(repeating: "•", count: min(value.count, 16)))
                    .font(.body.monospaced())
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
            }
        }
    }

    /// 纯展示标签行（无可复制）
    private func labelValueRow(
        icon: String,
        label: String,
        value: String,
        iconColor: Color
    ) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(iconColor)
                .frame(width: 20)
            Text(label)
                .font(.subheadline)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
        }
    }

    // MARK: - 剪贴板

    private func copyToClipboard(_ text: String, label: String) {
        viewModel.copyToClipboard(text)
        withAnimation {
            copyFeedback = label
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation {
                copyFeedback = nil
            }
        }
    }
}

#Preview("通用凭证") {
    NavigationStack {
        AccountDetailView(
            account: AccountDisplay(
                id: UUID(),
                category: .general,
                name: "示例网站",
                username: "user@example.com",
                password: "P@ssw0rd123!",
                url: "https://example.com",
                notes: "这是一个示例备注。",
                bankName: "",
                cardNumber: "",
                cardholderName: "",
                cardType: .debit,
                branch: "",
                phone: "",
                cvv: "",
                expiryDate: "",
                billingDay: "",
                repaymentDay: "",
                creditLimit: "",
                fullName: "",
                documentNumber: "",
                issuingAuthority: "",
                ssid: "",
                securityType: "",
                membershipLevel: "",
                insuranceType: "",
                insuredPerson: "",
                walletAddress: "",
                networkType: "",
                server: "",
                port: "",
                createdAt: Date(),
                modifiedAt: Date()
            ),
            viewModel: AccountViewModel()
        )
    }
}

#Preview("银行账户") {
    NavigationStack {
        AccountDetailView(
            account: AccountDisplay(
                id: UUID(),
                category: .bankAccount,
                name: "招商银行 储蓄卡",
                username: "",
                password: "123456",
                url: "",
                notes: "工资卡",
                bankName: "招商银行",
                cardNumber: "6214 8301 2345 6789",
                cardholderName: "张三",
                cardType: .savings,
                branch: "深圳福田支行",
                phone: "13800138000",
                cvv: "",
                expiryDate: "",
                billingDay: "",
                repaymentDay: "",
                creditLimit: "",
                fullName: "",
                documentNumber: "",
                issuingAuthority: "",
                ssid: "",
                securityType: "",
                membershipLevel: "",
                insuranceType: "",
                insuredPerson: "",
                walletAddress: "",
                networkType: "",
                server: "",
                port: "",
                createdAt: Date(),
                modifiedAt: Date()
            ),
            viewModel: AccountViewModel()
        )
    }
}
