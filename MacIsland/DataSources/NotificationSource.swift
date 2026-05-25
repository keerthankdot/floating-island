import AppKit
import Foundation

class NotificationSource {
    static let shared = NotificationSource()
    private(set) var recentNotifications: [String] = []

    private init() {}

    func startObserving() {
        DistributedNotificationCenter.default().addObserver(
            self,
            selector: #selector(handleNotification(_:)),
            name: nil,
            object: nil
        )
    }

    @objc private func handleNotification(_ notification: Notification) {
        #if DEBUG
        // do not log notification content in production
        #endif
    }
}
