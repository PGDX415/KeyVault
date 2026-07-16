//
//  AccountListView.swift
//  KeyVault
//
//  账户列表主页面：展示所有账户，支持搜索、新增、删除
//

import SwiftUI
import SwiftData

struct AccountListView: View {

    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = AccountViewModel()
    @State private var securityService = SecurityService.shared

    @State private var showAddSheet = false
    @State private var selectedAccount: AccountDisplay?
    @State private var showDeleteAlert = false
    @State private var accountToDelete: AccountDisplay?

    var body: some View {
        NavigationSplitView {
            // 侧边栏：账户列表
            listContent
                .navigationTitle("密钥阁")
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button {
                            securityService.lock()
                        } label: {
                            Image(systemName: "lock.fill")
                                .foregroundColor(.purple)
                        }
                        .help("锁定保险箱")
                    }
                }
                .searchable(
                    text: $viewModel.searchText,
                    placement: .sidebar,
                    prompt: "搜索账户名称或账号"
                )
        } detail: {
            // 详情区域
            if let account = selectedAccount {
                AccountDetailView(account: account, viewModel: viewModel)
            } else {
                emptyDetailView
            }
        }
        .sheet(isPresented: $showAddSheet) {
            AccountEditView(mode: .add, viewModel: viewModel)
        }
        .alert("确认删除", isPresented: $showDeleteAlert) {
            Button("取消", role: .cancel) {}
            Button("删除", role: .destructive) {
                if let account = accountToDelete {
                    deleteAccount(account)
                }
            }
        } message: {
            if let account = accountToDelete {
                Text("确定要删除「\(account.name)」吗？此操作不可撤销。")
            }
        }
        .onAppear {
            viewModel.configure(with: modelContext)
            viewModel.loadAccounts()
        }
    }

    // MARK: - 列表内容

    private var listContent: some View {
        List(selection: $selectedAccount) {
            if viewModel.filteredAccounts.isEmpty {
                emptyListView
            } else {
                ForEach(viewModel.filteredAccounts) { account in
                    AccountRowView(account: account)
                        .tag(account)
                        .swipeActions(edge: .trailing) {
                            Button(role: .destructive) {
                                accountToDelete = account
                                showDeleteAlert = true
                            } label: {
                                Label("删除", systemImage: "trash")
                            }
                        }
                }
            }
        }
        .overlay(alignment: .bottomTrailing) {
            // 新增按钮
            Button {
                showAddSheet = true
            } label: {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(.purple)
                    .shadow(color: .purple.opacity(0.3), radius: 8, y: 4)
            }
            .padding(20)
        }
        .refreshable {
            viewModel.loadAccounts()
        }
    }

    // MARK: - 空列表

    private var emptyListView: some View {
        VStack(spacing: 16) {
            Image(systemName: "shield.slash")
                .font(.system(size: 40))
                .foregroundColor(.secondary)

            if viewModel.searchText.isEmpty {
                Text("还没有保存的账户")
                    .font(.headline)
                    .foregroundColor(.secondary)
                Text("点击右下角 + 按钮添加第一个账户")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            } else {
                Text("未找到匹配的账户")
                    .font(.headline)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity, minHeight: 200)
        .listRowBackground(Color.clear)
    }

    // MARK: - 空详情

    private var emptyDetailView: some View {
        VStack(spacing: 16) {
            Image(systemName: "shield.checkered")
                .font(.system(size: 64))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.purple.opacity(0.6), .indigo.opacity(0.6)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            Text("密钥阁")
                .font(.title)
                .fontWeight(.semibold)
                .foregroundColor(.purple)

            Text("选择一个账户查看详情")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }

    // MARK: - 删除操作

    private func deleteAccount(_ account: AccountDisplay) {
        do {
            try viewModel.deleteAccount(id: account.id)
            if selectedAccount?.id == account.id {
                selectedAccount = nil
            }
        } catch {
            viewModel.errorMessage = "删除失败：\(error.localizedDescription)"
        }
    }
}

// MARK: - 账户行视图

struct AccountRowView: View {
    let account: AccountDisplay

    private var accentColor: Color {
        account.category == .bankAccount ? .blue : .purple
    }

    private var gradientColors: [Color] {
        account.category == .bankAccount
            ? [.blue, .cyan]
            : [.purple, .indigo]
    }

    private var subtitle: String {
        switch account.category {
        case .general:
            return account.username
        case .bankAccount:
            let parts = [account.cardNumber]
            return parts.filter { !$0.isEmpty }.joined(separator: " · ")
        }
    }

    var body: some View {
        HStack(spacing: 12) {
            // 分类图标头像
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: gradientColors,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 40, height: 40)

                Image(systemName: account.category.iconName)
                    .font(.headline)
                    .foregroundColor(.white)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(account.name)
                    .font(.headline)
                    .lineLimit(1)

                if !subtitle.isEmpty {
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }

            Spacer()

            // 分类标签
            Text(account.category.rawValue)
                .font(.caption2)
                .foregroundColor(accentColor)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(accentColor.opacity(0.1))
                .cornerRadius(4)
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    AccountListView()
        .modelContainer(for: Account.self, inMemory: true)
}
