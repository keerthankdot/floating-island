import Foundation

enum DataSourceType: String, Codable, CaseIterable {
    case calendar
    case reminders
    case whatsapp
    case gmail
    case notion
}

struct CalendarEvent: Codable, Identifiable {
    let id: String
    let title: String
    let startTime: String
    let startDate: Date
    let calendarName: String
}

struct ReminderItem: Codable, Identifiable {
    let id: String
    let title: String
    let dueDate: Date?
    let isOverdue: Bool
}

struct UnreadMessage: Codable, Identifiable {
    let id: String
    let sender: String
    let count: Int
    let source: DataSourceType
    let preview: String?
}

struct NotionTask: Codable, Identifiable {
    let id: String
    let title: String
    let status: String
}
