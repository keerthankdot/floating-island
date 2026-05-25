import SwiftUI

struct IslandPopover: View {
    @ObservedObject var state = AppState.shared

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
            Divider()
            content
            Divider()
            footer
        }
        .frame(width: 320)
        .background(.ultraThinMaterial)
    }

    private var header: some View {
        HStack {
            Image(systemName: "dot.radiowaves.left.and.right")
                .foregroundColor(.accentColor)
            Text("Mac Island")
                .font(.headline)
            Spacer()
            if state.isLoading {
                ProgressView().scaleEffect(0.6)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
    }

    private var content: some View {
        Group {
            if state.surfacedItems.isEmpty {
                emptyState
            } else {
                itemList
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
    }

    private var emptyState: some View {
        HStack {
            Image(systemName: "checkmark.circle")
                .foregroundColor(.green)
            Text("All clear. Go build.")
                .foregroundColor(.secondary)
                .font(.system(size: 13))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 8)
    }

    private var itemList: some View {
        VStack(alignment: .leading, spacing: 6) {
            ForEach(state.surfacedItems) { item in
                SurfaceCard(item: item)
            }
        }
    }

    private var footer: some View {
        HStack {
            if let updated = state.lastUpdated {
                Text("Updated \(updated.formatted(date: .omitted, time: .shortened))")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            Spacer()
            Button("Settings") {
                NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
                NSApp.activate(ignoringOtherApps: true)
            }
            .buttonStyle(.plain)
            .font(.caption)
            .foregroundColor(.accentColor)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
    }
}
