//
//  LockView.swift
//  KeyVault
//
//  解锁页面：优先 Face ID / Touch ID，备用主密码输入
//

import SwiftUI
import LocalAuthentication

struct LockView: View {

    @State private var securityService = SecurityService.shared

    @State private var password = ""
    @State private var showPassword = false
    @State private var isUnlocking = false
    @State private var showPasswordField = false

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            // 盾牌图标
            Image(systemName: "lock.shield.fill")
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

            Text("已锁定")
                .font(.title3)
                .foregroundColor(.secondary)
                .padding(.bottom, 48)

            // 生物识别解锁按钮
            if securityService.isBiometricAvailable {
                Button {
                    Task {
                        await authenticateWithBiometrics()
                    }
                } label: {
                    VStack(spacing: 12) {
                        Image(systemName: securityService.biometricTypeName == "面容 ID"
                              ? "faceid"
                              : "touchid")
                            .font(.system(size: 40))
                            .foregroundColor(.purple)

                        if isUnlocking {
                            ProgressView()
                                .tint(.purple)
                        } else {
                            Text("使用 \(securityService.biometricTypeName) 解锁")
                                .font(.headline)
                                .foregroundColor(.primary)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 32)
                    .background(Color(.systemGray6))
                    .cornerRadius(16)
                }
                .disabled(isUnlocking)
                .padding(.horizontal, 32)
                .padding(.bottom, 24)
            }

            // 备用密码解锁
            if showPasswordField || !securityService.isBiometricAvailable {
                VStack(spacing: 16) {
                    Divider()
                        .padding(.horizontal, 32)

                    Text("或使用主密码解锁")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .padding(.top, 8)

                    HStack {
                        if showPassword {
                            TextField("输入主密码", text: $password)
                                .textFieldStyle(.plain)
                                .textContentType(.password)
                                .submitLabel(.go)
                                .onSubmit {
                                    authenticateWithPassword()
                                }
                        } else {
                            SecureField("输入主密码", text: $password)
                                .textFieldStyle(.plain)
                                .textContentType(.password)
                                .submitLabel(.go)
                                .onSubmit {
                                    authenticateWithPassword()
                                }
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
                    .padding(.horizontal, 32)

                    // 密码错误提示
                    if securityService.hasPasswordError {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.red)
                            Text("主密码不正确，请重试")
                                .font(.caption)
                                .foregroundColor(.red)
                            Spacer()
                        }
                        .padding(.horizontal, 36)
                    }

                    Button {
                        authenticateWithPassword()
                    } label: {
                        HStack {
                            if isUnlocking {
                                ProgressView()
                                    .tint(.white)
                            }
                            Text("解锁")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            !password.isEmpty && !isUnlocking
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
                    .disabled(password.isEmpty || isUnlocking)
                    .padding(.horizontal, 32)
                    .padding(.top, 8)
                }
            } else {
                // 使用密码的入口
                Button {
                    withAnimation {
                        showPasswordField = true
                    }
                } label: {
                    Text("使用主密码解锁")
                        .font(.subheadline)
                        .foregroundColor(.purple)
                }
                .padding(.top, 16)
            }

            Spacer()
        }
        .background(Color(.systemBackground))
        .task {
            // 自动触发生物识别
            if securityService.isBiometricAvailable && !showPasswordField {
                await authenticateWithBiometrics()
            }
        }
    }

    // MARK: - 生物识别解锁

    private func authenticateWithBiometrics() async {
        isUnlocking = true

        // 在后台线程执行以免阻塞 UI
        do {
            try await securityService.unlockWithBiometrics()
        } catch {
            // 生物识别失败，静默处理（用户可以手动输入密码）
            // 如果是用户取消，不做任何提示
        }

        isUnlocking = false
    }

    // MARK: - 密码解锁

    private func authenticateWithPassword() {
        guard !password.isEmpty else { return }
        isUnlocking = true

        do {
            try securityService.unlockWithPassword(password)
            password = ""
        } catch {
            // 错误信息已在 SecurityService.hasPasswordError 中体现
        }

        isUnlocking = false
    }
}

#Preview {
    LockView()
}
