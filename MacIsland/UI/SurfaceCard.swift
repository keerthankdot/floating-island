import SwiftUI

struct SurfaceCard: View {
    let item: SurfacedItem

    var urgencyColor: Color {
        switch item.urgency {
        case .high: return .red
        case .medium: return .orange
        case .low: return .secondary
        }
    }

    var sourceIcon: String {
        switch item.type {
        case .calendar: return "calendar"
        case .reminders: return "checklist"
        case .whatsapp: return "message.fill"
        case .gmail: return "envelope.fill"
        case .notion: return "doc.text.fill"
        }
    }

    var body: some View {
        HStack(spacing: 10) {
            Circle()
                .fill(urgencyColor)
                .frame(width: 7, height: 7)

            Image(systemName: sourceIcon)
                .font(.system(size: 11))
                .foregroundColor(.secondary)
                .frame(width: 14)

            Text(item.message)
                .font(.system(size: 13))
                .lineLimit(2)

            Spacer()
        }
        .padding(.vertical, 5)
        .contentShape(Rectangle())
    }
}
