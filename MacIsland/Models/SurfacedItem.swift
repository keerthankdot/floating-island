import Foundation

enum Urgency: String, Codable {
    case high
    case medium
    case low
}

struct SurfacedItem: Codable, Identifiable {
    let id: UUID
    let type: DataSourceType
    let message: String
    let urgency: Urgency
    let source: String

    init(type: DataSourceType, message: String, urgency: Urgency, source: String) {
        self.id = UUID()
        self.type = type
        self.message = message
        self.urgency = urgency
        self.source = source
    }
}
