import Foundation

class ContextBuilder {
    static let shared = ContextBuilder()

    private init() {}

    func build() async -> ContextSnapshot {
        async let events = CalendarSource.shared.upcomingEvents()
        async let dueReminders = RemindersSource.shared.dueTodayReminders()
        async let overdueReminders = RemindersSource.shared.overdueReminders()
        let messages = WhatsAppSource.shared.unreadMessages()

        return ContextSnapshot(
            timestamp: Date(),
            upcomingEvents: await events,
            dueTodayReminders: await dueReminders,
            overdueReminders: await overdueReminders,
            unreadMessages: messages,
            notionTasks: []
        )
    }
}
