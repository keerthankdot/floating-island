import Foundation
import SQLite3

class WhatsAppSource {
    static let shared = WhatsAppSource()

    private let dbPath: String
    private var lastChecked: Date = Date().addingTimeInterval(-3600)

    private init() {
        let home = FileManager.default.homeDirectoryForCurrentUser.path
        dbPath = "\(home)/Library/Group Containers/group.com.apple.notificationcenter/db2/db"
    }

    func hasDiskAccess() -> Bool {
        FileManager.default.isReadableFile(atPath: dbPath)
    }

    func unreadMessages() -> [UnreadMessage] {
        guard hasDiskAccess() else { return [] }

        var db: OpaquePointer?
        guard sqlite3_open_v2(dbPath, &db, SQLITE_OPEN_READONLY, nil) == SQLITE_OK else { return [] }
        defer { sqlite3_close(db) }

        let cutoff = lastChecked.timeIntervalSinceReferenceDate + 978307200
        let query = """
            SELECT data, delivered_date FROM record
            WHERE bundleid = 'net.whatsapp.WhatsApp'
            AND delivered_date > ?
            ORDER BY delivered_date DESC
            LIMIT 50
        """

        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, query, -1, &stmt, nil) == SQLITE_OK else { return [] }
        defer { sqlite3_finalize(stmt) }

        sqlite3_bind_double(stmt, 1, cutoff)

        var senderCounts: [String: Int] = [:]
        var senderPreview: [String: String] = [:]

        while sqlite3_step(stmt) == SQLITE_ROW {
            guard let blob = sqlite3_column_blob(stmt, 0) else { continue }
            let size = sqlite3_column_bytes(stmt, 0)
            let data = Data(bytes: blob, count: Int(size))

            if let plist = try? PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any],
               let sender = extractSender(from: plist),
               let preview = extractPreview(from: plist) {
                senderCounts[sender, default: 0] += 1
                if senderPreview[sender] == nil {
                    senderPreview[sender] = preview
                }
            }
        }

        lastChecked = Date()

        return senderCounts.map { sender, count in
            UnreadMessage(
                id: "\(sender)-\(Date().timeIntervalSince1970)",
                sender: sender,
                count: count,
                source: .whatsapp,
                preview: senderPreview[sender]
            )
        }.sorted { $0.count > $1.count }
    }

    private func extractSender(from plist: [String: Any]) -> String? {
        // notificationCenter plist structure: aps > alert > title, or directly "title"
        if let aps = plist["aps"] as? [String: Any],
           let alert = aps["alert"] as? [String: Any],
           let title = alert["title"] as? String {
            return title
        }
        if let title = plist["title"] as? String { return title }
        return nil
    }

    private func extractPreview(from plist: [String: Any]) -> String? {
        if let aps = plist["aps"] as? [String: Any],
           let alert = aps["alert"] as? [String: Any],
           let body = alert["body"] as? String {
            return body
        }
        if let body = plist["body"] as? String { return body }
        return nil
    }
}
