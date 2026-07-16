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
        .onChange(of: scenePhase) { _, newPhase in
            switch newPhase {
            case .background, .inactive:
                // 切后台时启动延时锁定计时器
                securityService.scheduleAutoLock()
            case .active:
                // 回到前台时取消计时器
                securityService.cancelAutoLock()
            @unknown default:
                break
            }
        }
    }

    @Environment(\.scenePhase) private var scenePhase
}
