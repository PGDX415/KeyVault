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
        account.category == .bankAccount ? .blue : .purple
    }

    private var gradientColors: [Color] {
        account.category == .bankAccount
            ? [.blue, .cyan]
            : [.purple, .indigo]
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                headerSection

                Divider()

                // 分类图标
                categoryBadge

                // 根据分类显示不同字段
                switch account.category {
                case .general:
                    generalDetailSection
                case .bankAccount:
                    bankDetailSection
                }

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

                if account.category == .general && !account.url.isEmpty {
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

    // MARK: - 通用凭证详情

    private var generalDetailSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            // 用户名
            maskableInfoRow(
                icon: "person.fill",
                label: "账号",
                value: account.username,
                isVisible: true,
                iconColor: accentColor,
                onCopy: {
                    copyToClipboard(account.username, label: "账号已复制")
                }
            )

            // 密码
            maskableInfoRow(
                icon: "key.fill",
                label: "密码",
                value: account.password,
                isVisible: isPasswordVisible,
                iconColor: .orange,
                onToggle: { isPasswordVisible.toggle() }
            ) {
                copyToClipboard(account.password, label: "密码已复制")
            }

            // 网址
            if !account.url.isEmpty {
                infoRow(
                    icon: "link",
                    label: "网址",
                    value: account.url,
                    iconColor: accentColor
                ) {
                    copyToClipboard(account.url, label: "网址已复制")
                }
            }
        }
    }

    // MARK: - 银行账户详情

    private var bankDetailSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            // 银行名称
            if !account.bankName.isEmpty {
                labelValueRow(
                    icon: "building.columns.fill",
                    label: "发卡银行",
                    value: account.bankName,
                    iconColor: .blue
                )
            }

            // 卡类型
            labelValueRow(
                icon: "wallet.pass",
                label: "卡类型",
                value: account.cardType.rawValue,
                iconColor: .blue
            )

            // 银行卡号（可显示/隐藏）
            maskableInfoRow(
                icon: "creditcard.fill",
                label: "银行卡号",
                value: account.cardNumber,
                isVisible: isCardNumberVisible,
                iconColor: .blue,
                onToggle: { isCardNumberVisible.toggle() }
            ) {
                copyToClipboard(account.cardNumber, label: "卡号已复制")
            }

            // 户名
            if !account.cardholderName.isEmpty {
                maskableInfoRow(
                    icon: "person.text.rectangle.fill",
                    label: "户名",
                    value: account.cardholderName,
                    isVisible: true,
                    iconColor: .blue,
                    onCopy: {
                        copyToClipboard(account.cardholderName, label: "户名已复制")
                    }
                )
            }

            // CVV 安全码
            if !account.cvv.isEmpty {
                maskableInfoRow(
                    icon: "number.square.fill",
                    label: "CVV 安全码",
                    value: account.cvv,
                    isVisible: isCVVVisible,
                    iconColor: .orange,
                    onToggle: { isCVVVisible.toggle() }
                ) {
                    copyToClipboard(account.cvv, label: "CVV 已复制")
                }
            }

            // 有效期
            if !account.expiryDate.isEmpty {
                infoRow(
                    icon: "calendar",
                    label: "有效期",
                    value: account.expiryDate,
                    iconColor: .orange
                ) {
                    copyToClipboard(account.expiryDate, label: "有效期已复制")
                }
            }

            // 密码（ATM PIN）
            if !account.password.isEmpty {
                maskableInfoRow(
                    icon: "key.fill",
                    label: "ATM/查询密码",
                    value: account.password,
                    isVisible: isPasswordVisible,
                    iconColor: .orange,
                    onToggle: { isPasswordVisible.toggle() }
                ) {
                    copyToClipboard(account.password, label: "密码已复制")
                }
            }

            // 开户行
            if !account.branch.isEmpty {
                labelValueRow(
                    icon: "mappin.and.ellipse",
                    label: "开户行",
                    value: account.branch,
                    iconColor: .gray
                )
            }

            // 预留手机号
            if !account.phone.isEmpty {
                infoRow(
                    icon: "phone.fill",
                    label: "预留手机号",
                    value: account.phone,
                    iconColor: .gray
                ) {
                    copyToClipboard(account.phone, label: "手机号已复制")
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
                createdAt: Date(),
                modifiedAt: Date()
            ),
            viewModel: AccountViewModel()
        )
    }
}
