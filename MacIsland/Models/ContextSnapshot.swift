import Foundation

struct ContextSnapshot: Codable {
    let timestamp: Date
    let upcomingEvents: [CalendarEvent]
    let dueTodayReminders: [ReminderItem]
    let overdueReminders: [ReminderItem]
    let unreadMessages: [UnreadMessage]
    let notionTasks: [NotionTask]
}
