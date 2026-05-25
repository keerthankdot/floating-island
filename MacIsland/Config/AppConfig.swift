import Foundation

struct AppConfig {
    static let pollIntervalSeconds: TimeInterval = 60
    static let meetingAlertWindowMinutes: Int = 30
    static let maxSurfacedItems: Int = 3
    static let enabledSources: Set<DataSourceType> = [.calendar, .reminders, .whatsapp]
    static let claudeModel = "claude-sonnet-4-6"
    static let claudeMaxTokens = 500
    static let keychainService = "com.ascnd.macisland"
}
