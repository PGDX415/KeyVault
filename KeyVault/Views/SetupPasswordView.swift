//
//  SetupPasswordView.swift
//  KeyVault
//
//  首次设置主密码页面
//

import SwiftUI

struct SetupPasswordView: View {

    @State private var securityService = SecurityService.shared

    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var showPassword = false
    @State private var showConfirmPassword = false
    @State private var errorMessage: String?
    @State private var isSetting = false

    // 密码强度验证
    private var passwordStrength: (level: String, color: Color) {
        if password.count < 6 {
            return ("太短", .red)
        } else if password.count < 10 {
            return ("中等", .orange)
        } else if password.count < 16 {
            return ("良好", .yellow)
        } else {
            return ("强", .green)
        }
    }

    private var isPasswordValid: Bool {
        password.count >= 6 && password == confirmPassword
    }

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            // 盾牌图标
            Image(systemName: "shield.checkered")
                .font(.system(size: 64))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.purple, .indigo],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .padding(.bottom, 16)

            // 标题
            Text("密钥阁")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.purple)

            Text("KeyVault")
                .font(.title3)
                .foregroundColor(.secondary)
                .padding(.bottom, 40)

            // 说明文字
            Text("设置主密码以保护您的账户信息安全")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
                .padding(.bottom, 32)

            // 密码输入
            VStack(spacing: 16) {
                // 主密码
                HStack {
                    if showPassword {
                        TextField("主密码（至少 6 位）", text: $password)
                            .textFieldStyle(.plain)
                            .textContentType(.newPassword)
                    } else {
                        SecureField("主密码（至少 6 位）", text: $password)
                            .textFieldStyle(.plain)
                            .textContentType(.newPassword)
                    }
                    Button {
                        showPassword.toggle()
                    } label: {
                        Image(systemName: showPassword ? "eye.slash" : "eye")
                            .foregroundColor(.secondary)
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)

                // 密码强度指示
                if !password.isEmpty {
                    HStack {
                        Text("密码强度：")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(passwordStrength.level)
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(passwordStrength.color)
                        Spacer()
                    }
                    .padding(.horizontal, 4)
                }

                // 确认密码
                HStack {
                    if showConfirmPassword {
                        TextField("确认主密码", text: $confirmPassword)
                            .textFieldStyle(.plain)
                            .textContentType(.newPassword)
                    } else {
                        SecureField("确认主密码", text: $confirmPassword)
                            .textFieldStyle(.plain)
                            .textContentType(.newPassword)
                    }
                    Button {
                        showConfirmPassword.toggle()
                    } label: {
                        Image(systemName: showConfirmPassword ? "eye.slash" : "eye")
                            .foregroundColor(.secondary)
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)

                // 密码不匹配提示
                if !confirmPassword.isEmpty && password != confirmPassword {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.orange)
                        Text("两次输入的密码不一致")
                            .font(.caption)
                            .foregroundColor(.orange)
                        Spacer()
                    }
                    .padding(.horizontal, 4)
                }
            }
            .padding(.horizontal, 32)

            // 错误信息
            if let error = errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundColor(.red)
                    .padding(.top, 12)
                    .padding(.horizontal, 32)
            }

            // 设置按钮
            Button {
                setupPassword()
            } label: {
                HStack {
                    if isSetting {
                        ProgressView()
                            .tint(.white)
                    }
                    Text("完成设置")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(
                    isPasswordValid && !isSetting
                        ? AnyShapeStyle(
                            LinearGradient(
                                colors: [.purple, .indigo],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        : AnyShapeStyle(Color.gray.opacity(0.3))
                )
                .foregroundColor(.white)
                .cornerRadius(12)
            }
            .disabled(!isPasswordValid || isSetting)
            .padding(.horizontal, 32)
            .padding(.top, 32)

            Spacer()

            // 安全声明
            Text("主密码仅在本地设备加密存储，不会上传到任何服务器")
                .font(.caption2)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
                .padding(.bottom, 32)
        }
        .background(Color(.systemBackground))
    }

    private func setupPassword() {
        isSetting = true
        errorMessage = nil

        do {
            try securityService.setupMasterPassword(password)
            isSetting = false
        } catch {
            errorMessage = "设置失败：\(error.localizedDescription)"
            isSetting = false
        }
    }
}

#Preview {
    SetupPasswordView()
}
