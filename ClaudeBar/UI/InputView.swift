import SwiftUI

struct InputView: View {
    let event: ClaudeEvent
    let prompt: String
    @Environment(SessionManager.self) private var sessionManager
    @Environment(AppSettings.self) private var settings
    @State private var inputText = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label {
                Text("Input Needed")
                    .font(.subheadline.weight(.medium))
            } icon: {
                Image(systemName: "keyboard.fill")
                    .foregroundStyle(.purple)
            }

            Text(prompt)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(4)

            HStack(spacing: 8) {
                TextField("Type response...", text: $inputText)
                    .textFieldStyle(.roundedBorder)
                    .font(.caption)
                    .onSubmit {
                        guard !inputText.isEmpty else { return }
                        respond(inputText)
                    }

                Button("Send") {
                    guard !inputText.isEmpty else { return }
                    respond(inputText)
                }
                .buttonStyle(.borderedProminent)
                .disabled(inputText.isEmpty)
            }
        }
        .padding(16)
    }

    private func respond(_ text: String) {
        let adapter = TerminalAdapterFactory.create(for: settings.terminalType, event: event)
        sessionManager.respond(text, for: event, using: adapter)
    }
}
