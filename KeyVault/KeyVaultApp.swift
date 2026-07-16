//
//  KeyVaultApp.swift
//  KeyVault
//
//  密钥阁 App 入口：管理安全状态、自动锁定、CloudKit iCloud 同步
//

import SwiftUI
import SwiftData
import CloudKit

@main
struct KeyVaultApp: App {

    @State private var securityService = SecurityService.shared
    @State private var syncMonitor = SyncMonitor.shared

    /// SwiftData 持久化容器：加密存储 + CloudKit 自动同步
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Account.self,
        ])
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            cloudKitDatabase: .private("iCloud.com.gongdexin.paul.KeyVault")
        )

        do {
            let container = try ModelContainer(
                for: schema,
                configurations: [modelConfiguration]
            )
            // 启动远程同步监听
            SyncMonitor.shared.startObserving(container: container)
            return container
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
                securityService.scheduleAutoLock()
            case .active:
                securityService.cancelAutoLock()
                // 回到前台时检查同步状态
                syncMonitor.refreshStatus()
            @unknown default:
                break
            }
        }
    }

    @Environment(\.scenePhase) private var scenePhase
}
