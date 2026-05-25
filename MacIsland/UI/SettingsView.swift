import SwiftUI

struct SettingsView: View {
    @State private var apiKey: String = KeychainHelper.retrieve(key: SecretsKey.anthropicAPIKey) ?? ""
    @State private var savedBanner: Bool = false
    @ObservedObject private var state = AppState.shared

    var body: some View {
        Form {
            Section("API Keys") {
                SecureField("Anthropic API Key", text: $apiKey)
                    .textFieldStyle(.roundedBorder)
                Button("Save") { saveAPIKey() }
                    .disabled(apiKey.isEmpty)
                if savedBanner {
                    Label("Saved", systemImage: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .font(.caption)
                }
            }

            Section("Data Sources") {
                SourceToggle(label: "Calendar", icon: "calendar", source: .calendar)
                SourceToggle(label: "Reminders", icon: "checklist", source: .reminders)
                SourceToggle(label: "WhatsApp", icon: "message.fill", source: .whatsapp)
            }

            Section("Permissions") {
                PermissionRow(label: "Calendar Access", granted: state.hasCalendarAccess) {
                    Task { state.hasCalendarAccess = await CalendarSource.shared.requestAccess() }
                }
                PermissionRow(label: "Reminders Access", granted: state.hasRemindersAccess) {
                    Task { state.hasRemindersAccess = await RemindersSource.shared.requestAccess() }
                }
                PermissionRow(label: "Full Disk Access", granted: state.hasFullDiskAccess) {
                    NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_AllFiles")!)
                }
            }

            Section {
                Button("Refresh Now") {
                    Task { await PollingManager().tick() }
                }
            }
        }
        .formStyle(.grouped)
        .frame(width: 420, height: 480)
        .navigationTitle("Mac Island Settings")
    }

    private func saveAPIKey() {
        KeychainHelper.store(key: SecretsKey.anthropicAPIKey, value: apiKey)
        savedBanner = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { savedBanner = false }
    }
}

struct SourceToggle: View {
    let label: String
    let icon: String
    let source: DataSourceType
    @ObservedObject private var state = AppState.shared

    var body: some View {
        Toggle(isOn: Binding(
            get: { state.enabledSources.contains(source) },
            set: { on in
                if on { state.enabledSources.insert(source) }
                else { state.enabledSources.remove(source) }
            }
        )) {
            Label(label, systemImage: icon)
        }
    }
}

struct PermissionRow: View {
    let label: String
    let granted: Bool
    let action: () -> Void

    var body: some View {
        HStack {
            Label(label, systemImage: granted ? "checkmark.circle.fill" : "xmark.circle.fill")
                .foregroundColor(granted ? .green : .red)
            Spacer()
            if !granted {
                Button("Grant") { action() }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
            }
        }
    }
}
