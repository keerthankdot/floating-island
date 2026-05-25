import Foundation
import Combine

class AppState: ObservableObject {
    static let shared = AppState()

    @Published var surfacedItems: [SurfacedItem] = []
    @Published var isLoading: Bool = false
    @Published var lastUpdated: Date?
    @Published var enabledSources: Set<DataSourceType> = AppConfig.enabledSources
    @Published var hasCalendarAccess: Bool = false
    @Published var hasRemindersAccess: Bool = false
    @Published var hasFullDiskAccess: Bool = false

    private init() {
        hasFullDiskAccess = WhatsAppSource.shared.hasDiskAccess()
    }
}
