//
//  SettingsView.swift
//  KeyVault
//
//  设置页面：自动锁定超时、安全选项
//

import SwiftUI

struct SettingsView: View {

    @State private var securityService = SecurityService.shared

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                // MARK: 自动锁定
                Section {
                    Picker(selection: Binding(
                        get: { securityService.autoLockTimeout },
                        set: { securityService.autoLockTimeout = $0 }
                    )) {
                        ForEach(SecurityService.autoLockOptions, id: \.seconds) { option in
                            Text(option.label).tag(option.seconds)
                        }
                    } label: {
                        Label("自动锁定", systemImage: "timer")
                            .foregroundColor(.orange)
                    }
                } header: {
                    Text("锁定设置")
                } footer: {
                    Text("切换到后台超过所选时长后，密钥阁将自动锁定，需要重新解锁才能访问。")
                }

                // MARK: 锁定按钮
                Section {
                    Button {
                        securityService.lock()
                        dismiss()
                    } label: {
                        HStack {
                            Image(systemName: "lock.fill")
                                .foregroundColor(.purple)
                            Text("立即锁定")
                                .foregroundColor(.primary)
                            Spacer()
                        }
                    }
                } header: {
                    Text("手动操作")
                } footer: {
                    Text("锁定后需要面容 ID/触控 ID 或主密码重新解锁。")
                }

                // MARK: 安全提示
                Section {
                    HStack {
                        Image(systemName: "shield.checkered")
                            .font(.title2)
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.purple, .indigo],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                        VStack(alignment: .leading, spacing: 4) {
                            Text("密钥阁")
                                .font(.headline)
                                .foregroundColor(.purple)
                            Text("所有数据均在设备本地加密存储，不会上传到任何第三方服务器。")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                } header: {
                    Text("关于")
                }
            }
            .navigationTitle("设置")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("完成") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    SettingsView()
}
