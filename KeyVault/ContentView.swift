//
//  AppRootView.swift
//  KeyVault
//
//  应用根视图：根据安全状态切换不同页面
//  - 未设置主密码 → 设置密码页
//  - 已设置但未解锁 → 解锁页
//  - 已解锁 → 账户列表主页面
//

import SwiftUI

struct AppRootView: View {

    @State private var securityService = SecurityService.shared

    var body: some View {
        Group {
            if securityService.isUnlocked {
                AccountListView()
                    .transition(.opacity)
            } else if securityService.isSetupComplete {
                LockView()
                    .transition(.opacity)
            } else {
                SetupPasswordView()
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: securityService.isUnlocked)
        .animation(.easeInOut(duration: 0.3), value: securityService.isSetupComplete)
        .preferredColorScheme(.none) // 跟随系统深色/浅色模式
    }
}

#Preview("未设置") {
    AppRootView()
}

#Preview("已锁定") {
    AppRootView()
}
