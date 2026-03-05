import SwiftUI

struct SettingsView: View {
    @Environment(AppSettings.self) private var settings

    var body: some View {
        @Bindable var settings = settings

        Form {
            Section("Terminal") {
                Picker("Terminal App", selection: $settings.terminalType) {
                    ForEach(TerminalType.allCases) { type in
                        Text(type.displayName).tag(type)
                    }
                }
            }

            Section("Notifications") {
                Toggle("Auto-show popup", isOn: $settings.autoPopup)
                Toggle("Sound", isOn: $settings.soundEnabled)
            }

            Section("Socket") {
                LabeledContent("Path") {
                    Text("/tmp/claudebar.sock")
                        .font(.system(.caption, design: .monospaced))
                        .textSelection(.enabled)
                }
            }
        }
        .formStyle(.grouped)
        .frame(width: 380, height: 280)
    }
}
