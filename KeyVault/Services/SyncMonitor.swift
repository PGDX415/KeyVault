//
//  SyncMonitor.swift
//  KeyVault
//
//  CloudKit iCloud 同步状态监听器
//
//  职责：
//  - 监听 NSPersistentCloudKitContainer 同步事件
//  - 提供实时同步状态（空闲/同步中/错误/不可用）
//  - 远程数据变更时通知 ViewModel 刷新
//

import Foundation
import SwiftData
import CoreData
import CloudKit
import Observation
import SwiftUI

/// 同步状态
enum SyncStatus: Equatable {
    /// 空闲：无同步活动
    case idle
    /// 同步中：正在上传/下载
    case syncing
    /// 已同步完成
    case synced
    /// 同步错误
    case error(String)
    /// iCloud 账户不可用（未登录或无网络）
    case unavailable

    var iconName: String {
        switch self {
        case .idle:      return "icloud"
        case .syncing:   return "icloud.and.arrow.up"
        case .synced:    return "icloud.fill"
        case .error:     return "icloud.slash"
        case .unavailable: return "icloud.slash"
        }
    }

    var color: Color {
        switch self {
        case .syncing:     return .blue
        case .error:       return .red
        case .unavailable: return .gray
        default:           return .green
        }
    }

    var description: String {
        switch self {
        case .idle:         return "已就绪"
        case .syncing:      return "同步中…"
        case .synced:       return "已同步"
        case .error(let e): return "同步失败：\(e)"
        case .unavailable:  return "iCloud 不可用"
        }
    }
}

/// CloudKit 同步监听器（单例）
@MainActor
@Observable
final class SyncMonitor {

    static let shared = SyncMonitor()

    /// 当前同步状态
    private(set) var status: SyncStatus = .idle

    /// 用来通知 AccountViewModel 远程数据已变更
    var remoteChangeCount = 0

    private var container: ModelContainer?
    private let containerIdentifier = "iCloud.com.gongdexin.paul.KeyVault"

    private init() {}

    // MARK: - 启动监听

    /// 注入 ModelContainer 并开始监听同步事件
    func startObserving(container: ModelContainer) {
        self.container = container

        // 监听 CloudKit 同步事件
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleSyncEvent(_:)),
            name: NSPersistentCloudKitContainer.eventChangedNotification,
            object: nil
        )

        // 初始检查 iCloud 状态
        refreshStatus()
    }

    // MARK: - iCloud 账户状态

    /// 检查 iCloud 账户是否可用
    func refreshStatus() {
        Task {
            let accountStatus = try? await CKContainer(
                identifier: containerIdentifier
            ).accountStatus()
            switch accountStatus {
            case .available:
                if case .unavailable = status {
                    status = .idle
                }
            case .noAccount, .restricted, .couldNotDetermine, nil:
                status = .unavailable
            @unknown default:
                status = .unavailable
            }
        }
    }

    // MARK: - 同步事件处理

    @objc private func handleSyncEvent(_ notification: Notification) {
        guard let event = notification.userInfo?[
            NSPersistentCloudKitContainer.eventNotificationUserInfoKey
        ] as? NSPersistentCloudKitContainer.Event else {
            return
        }

        Task { @MainActor in
            switch event.type {
            case .setup:
                status = .syncing

            case .import:
                status = .syncing
                // 导入完成后触发远程变更计数，让 View 刷新
                if event.succeeded {
                    remoteChangeCount += 1
                    status = .synced
                    // 短暂显示「已同步」后恢复空闲
                    try? await Task.sleep(nanoseconds: 2_000_000_000)
                    if case .synced = status {
                        status = .idle
                    }
                } else if let error = event.error {
                    status = .error(error.localizedDescription)
                }

            case .export:
                status = .syncing
                if event.succeeded {
                    status = .synced
                    try? await Task.sleep(nanoseconds: 2_000_000_000)
                    if case .synced = status {
                        status = .idle
                    }
                } else if let error = event.error {
                    status = .error(error.localizedDescription)
                }

            @unknown default:
                break
            }
        }
    }
}
