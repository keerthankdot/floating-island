import EventKit
import Foundation

class CalendarSource {
    static let shared = CalendarSource()
    private let store = EKEventStore()

    private init() {}

    func requestAccess() async -> Bool {
        if #available(macOS 14.0, *) {
            return (try? await store.requestFullAccessToEvents()) ?? false
        }
        return await withCheckedContinuation { cont in
            store.requestAccess(to: .event) { granted, _ in cont.resume(returning: granted) }
        }
    }

    func upcomingEvents(withinHours hours: Int = 8) -> [CalendarEvent] {
        let now = Date()
        guard let end = Calendar.current.date(byAdding: .hour, value: hours, to: now) else { return [] }
        let pred = store.predicateForEvents(withStart: now, end: end, calendars: nil)
        return store.events(matching: pred)
            .sorted { $0.startDate < $1.startDate }
            .prefix(5)
            .map { CalendarEvent(
                id: $0.eventIdentifier ?? UUID().uuidString,
                title: $0.title ?? "Untitled",
                startTime: formatTime($0.startDate),
                startDate: $0.startDate,
                calendarName: $0.calendar?.title ?? ""
            )}
    }

    func eventStartingWithinMinutes(_ mins: Int) -> CalendarEvent? {
        upcomingEvents(withinHours: 1).first {
            let diff = $0.startDate.timeIntervalSince(Date())
            return diff > 0 && diff <= Double(mins * 60)
        }
    }

    private func formatTime(_ date: Date) -> String {
        let f = DateFormatter()
        f.timeStyle = .short
        f.dateStyle = .none
        return f.string(from: date)
    }
}
