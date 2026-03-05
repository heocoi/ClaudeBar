import SwiftUI

struct PermissionView: View {
    let event: ClaudeEvent
    @Environment(SessionManager.self) private var sessionManager
    @Environment(AppSettings.self) private var settings

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Tool info
            Label {
                Text(event.toolName ?? "Permission Request")
                    .font(.subheadline.weight(.medium))
            } icon: {
                Image(systemName: "exclamationmark.shield.fill")
                    .foregroundStyle(.orange)
            }

            // Command/input preview
            if let preview = commandPreview {
                Text(preview)
                    .font(.system(.caption, design: .monospaced))
                    .padding(8)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(.quaternary)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                    .lineLimit(5)
            }

            if let message = event.message, event.toolName == nil {
                Text(message)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(3)
            }

            // Action buttons
            HStack(spacing: 8) {
                Button("Deny") {
                    respond("n")
                }
                .buttonStyle(.bordered)

                Spacer()

                Button("Allow") {
                    respond("y")
                }
                .buttonStyle(.borderedProminent)
                .tint(.orange)
            }
        }
        .padding(16)
    }

    private var commandPreview: String? {
        if let input = event.toolInput {
            if let command = input["command"] as? String {
                return command
            }
            // For file edits, show file path
            if let filePath = input["file_path"] as? String ?? input["filePath"] as? String {
                return filePath
            }
        }
        return nil
    }

    private func respond(_ text: String) {
        let adapter = TerminalAdapterFactory.create(for: settings.terminalType, event: event)
        sessionManager.respond(text, for: event, using: adapter)
    }
}
