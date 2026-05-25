import EventKit
import Foundation

class RemindersSource {
    static let shared = RemindersSource()
    private let store = EKEventStore()

    private init() {}

    func requestAccess() async -> Bool {
        if #available(macOS 14.0, *) {
            return (try? await store.requestFullAccessToReminders()) ?? false
        }
        return await withCheckedContinuation { cont in
            store.requestAccess(to: .reminder) { granted, _ in cont.resume(returning: granted) }
        }
    }

    func dueTodayReminders() async -> [ReminderItem] {
        let start = Calendar.current.startOfDay(for: Date())
        guard let end = Calendar.current.date(byAdding: .day, value: 1, to: start) else { return [] }
        let pred = store.predicateForIncompleteReminders(
            withDueDateStarting: start,
            ending: end,
            calendars: nil
        )
        return await fetchReminders(pred: pred, overdue: false)
    }

    func overdueReminders() async -> [ReminderItem] {
        let now = Date()
        let distantPast = Date.distantPast
        let pred = store.predicateForIncompleteReminders(
            withDueDateStarting: distantPast,
            ending: Calendar.current.startOfDay(for: now),
            calendars: nil
        )
        return await fetchReminders(pred: pred, overdue: true)
    }

    private func fetchReminders(pred: NSPredicate, overdue: Bool) async -> [ReminderItem] {
        await withCheckedContinuation { cont in
            store.fetchReminders(matching: pred) { reminders in
                let items = (reminders ?? []).map { r in
                    ReminderItem(
                        id: r.calendarItemIdentifier,
                        title: r.title ?? "Untitled",
                        dueDate: r.dueDateComponents?.date,
                        isOverdue: overdue
                    )
                }
                cont.resume(returning: items)
            }
        }
    }
}
