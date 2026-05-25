import Foundation

struct ClaudeResponse: Decodable {
    struct Content: Decodable {
        let text: String
    }
    let content: [Content]
}

class BrainEngine {
    static let shared = BrainEngine()

    private init() {}

    func surface(snapshot: ContextSnapshot) async -> [SurfacedItem] {
        guard let apiKey = Secrets.anthropicAPIKey, !apiKey.isEmpty else {
            return fallbackSurface(snapshot: snapshot)
        }

        let prompt = buildPrompt(snapshot)
        let body: [String: Any] = [
            "model": AppConfig.claudeModel,
            "max_tokens": AppConfig.claudeMaxTokens,
            "system": systemPrompt,
            "messages": [["role": "user", "content": prompt]]
        ]

        do {
            let rawJSON = try await callClaudeAPI(body: body)
            return parse(json: rawJSON)
        } catch {
            #if DEBUG
            print("BrainEngine error: \(error)")
            #endif
            return fallbackSurface(snapshot: snapshot)
        }
    }

    private var systemPrompt: String {
        """
        You are Mac Island, an ambient assistant living in the macOS menu bar.
        Your ONLY job: decide what the user must know RIGHT NOW.
        Rules:
        - Surface maximum 3 items
        - Prioritize by urgency: meetings starting < 30 min > overdue tasks > unread messages
        - Be brutally concise. Each item: 1 sentence, < 12 words
        - Format: JSON array of {type, message, urgency: "high"|"medium"|"low", source}
        - If nothing urgent: return empty array []
        - Never explain yourself. Respond with valid JSON only.
        Examples:
        [{"type":"calendar","message":"Wakefit standup in 28 mins","urgency":"high","source":"calendar"},{"type":"message","message":"3 unread WhatsApps from Sahil","urgency":"medium","source":"whatsapp"}]
        """
    }

    private func buildPrompt(_ snapshot: ContextSnapshot) -> String {
        var lines: [String] = ["Current time: \(snapshot.timestamp.formatted())"]

        if !snapshot.upcomingEvents.isEmpty {
            let evts = snapshot.upcomingEvents.prefix(3).map { "\($0.title) at \($0.startTime)" }.joined(separator: ", ")
            lines.append("Upcoming events: \(evts)")
        }
        if !snapshot.unreadMessages.isEmpty {
            let msgs = snapshot.unreadMessages.map { "\($0.count) from \($0.sender) via \($0.source.rawValue)" }.joined(separator: ", ")
            lines.append("Unread messages: \(msgs)")
        }
        if !snapshot.overdueReminders.isEmpty {
            lines.append("Overdue: \(snapshot.overdueReminders.map { $0.title }.joined(separator: ", "))")
        }
        if !snapshot.dueTodayReminders.isEmpty {
            lines.append("Due today: \(snapshot.dueTodayReminders.map { $0.title }.joined(separator: ", "))")
        }

        lines.append("\nWhat should I surface right now? Respond in JSON only.")
        return lines.joined(separator: "\n")
    }

    private func callClaudeAPI(body: [String: Any]) async throws -> String {
        guard let apiKey = Secrets.anthropicAPIKey else {
            throw URLError(.userAuthenticationRequired)
        }

        var request = URLRequest(url: URL(string: "https://api.anthropic.com/v1/messages")!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        request.timeoutInterval = 15

        let (data, _) = try await URLSession.shared.data(for: request)
        let decoded = try JSONDecoder().decode(ClaudeResponse.self, from: data)
        return decoded.content.first?.text ?? "[]"
    }

    private func parse(json: String) -> [SurfacedItem] {
        guard let data = json.data(using: .utf8),
              let raw = try? JSONSerialization.jsonObject(with: data) as? [[String: String]] else {
            return []
        }
        return raw.compactMap { dict -> SurfacedItem? in
            guard let typeStr = dict["type"],
                  let message = dict["message"],
                  let urgencyStr = dict["urgency"],
                  let source = dict["source"],
                  let type_ = DataSourceType(rawValue: typeStr),
                  let urgency = Urgency(rawValue: urgencyStr) else { return nil }
            return SurfacedItem(type: type_, message: message, urgency: urgency, source: source)
        }
    }

    // Rule-based fallback when no API key set
    private func fallbackSurface(snapshot: ContextSnapshot) -> [SurfacedItem] {
        var items: [SurfacedItem] = []

        if let soon = snapshot.upcomingEvents.first(where: {
            let diff = $0.startDate.timeIntervalSince(Date())
            return diff > 0 && diff <= Double(AppConfig.meetingAlertWindowMinutes * 60)
        }) {
            let mins = Int(soon.startDate.timeIntervalSince(Date()) / 60)
            items.append(SurfacedItem(type: .calendar, message: "\(soon.title) in \(mins) mins", urgency: .high, source: "calendar"))
        }

        for r in snapshot.overdueReminders.prefix(1) {
            items.append(SurfacedItem(type: .reminders, message: "Overdue: \(r.title)", urgency: .high, source: "reminders"))
        }

        if !snapshot.unreadMessages.isEmpty {
            let total = snapshot.unreadMessages.reduce(0) { $0 + $1.count }
            let names = snapshot.unreadMessages.prefix(2).map { $0.sender }.joined(separator: ", ")
            items.append(SurfacedItem(type: .whatsapp, message: "\(total) unread from \(names)", urgency: .medium, source: "whatsapp"))
        }

        return Array(items.prefix(AppConfig.maxSurfacedItems))
    }
}
