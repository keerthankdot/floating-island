import Foundation
import AppKit

class PollingManager {
    private var timer: Timer?

    func start() {
        timer = Timer.scheduledTimer(withTimeInterval: AppConfig.pollIntervalSeconds, repeats: true) { _ in
            Task { await self.tick() }
        }
        Task { await tick() }
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }

    func tick() async {
        await MainActor.run { AppState.shared.isLoading = true }

        let snapshot = await ContextBuilder.shared.build()
        let items = await BrainEngine.shared.surface(snapshot: snapshot)

        await MainActor.run {
            AppState.shared.surfacedItems = items
            AppState.shared.lastUpdated = Date()
            AppState.shared.isLoading = false
            updateMenuBarIcon(items: items)
        }
    }

    private func updateMenuBarIcon(items: [SurfacedItem]) {
        guard let app = NSApplication.shared.delegate as? AppDelegate,
              let button = app.statusItem?.button else { return }

        let hasHigh = items.contains { $0.urgency == .high }
        let hasMedium = items.contains { $0.urgency == .medium }

        if hasHigh {
            button.image = NSImage(systemSymbolName: "exclamationmark.bubble.fill", accessibilityDescription: "Mac Island — urgent")
        } else if hasMedium {
            button.image = NSImage(systemSymbolName: "bubble.left.and.bubble.right.fill", accessibilityDescription: "Mac Island — info")
        } else {
            button.image = NSImage(systemSymbolName: "dot.radiowaves.left.and.right", accessibilityDescription: "Mac Island")
        }
    }
}
