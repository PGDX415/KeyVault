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

        // 尝试创建容器；若旧数据库 schema 不兼容，则删除旧库重建
        let storeURL = URL.applicationSupportDirectory
            .appendingPathComponent("default.store")
        let walURL = storeURL.appendingPathExtension("wal")
        let shmURL = storeURL.appendingPathExtension("shm")

        func cleanupOldStore() {
            for url in [storeURL, walURL, shmURL] {
                try? FileManager.default.removeItem(at: url)
            }
        }

        do {
            let container = try ModelContainer(
                for: schema,
                configurations: [modelConfiguration]
            )
            SyncMonitor.shared.startObserving(container: container)
            return container
        } catch {
            // schema 不兼容 → 删除旧数据库重试
            cleanupOldStore()
            do {
                let container = try ModelContainer(
                    for: schema,
                    configurations: [modelConfiguration]
                )
                SyncMonitor.shared.startObserving(container: container)
                return container
            } catch {
                // CloudKit 不可用时降级为纯本地存储
                cleanupOldStore()
                let localConfig = ModelConfiguration(
                    schema: schema,
                    isStoredInMemoryOnly: false
                )
                do {
                    let container = try ModelContainer(
                        for: schema,
                        configurations: [localConfig]
                    )
                    print("⚠️ CloudKit 不可用，已降级为纯本地存储")
                    return container
                } catch {
                    fatalError("无法创建数据库容器: \(error)")
                }
            }
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
