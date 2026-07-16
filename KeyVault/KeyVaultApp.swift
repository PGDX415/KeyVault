//
//  KeyVaultApp.swift
//  KeyVault
//
//  密钥阁 App 入口：管理安全状态、自动锁定、数据持久化
//

import SwiftUI
import SwiftData

@main
struct KeyVaultApp: App {

    @State private var securityService = SecurityService.shared

    /// SwiftData 持久化容器：存储加密后的 Account 模型
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Account.self,
        ])
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false
        )

        do {
            return try ModelContainer(
                for: schema,
                configurations: [modelConfiguration]
            )
        } catch {
            fatalError("无法创建数据库容器: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            AppRootView()
        }
        .modelContainer(sharedModelContainer)
        // 监听应用生命周期，切后台时自动锁定
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .background || newPhase == .inactive {
                securityService.lock()
            }
        }
    }

    @Environment(\.scenePhase) private var scenePhase
}
