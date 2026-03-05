import SwiftUI

struct QuestionView: View {
    let event: ClaudeEvent
    @Environment(SessionManager.self) private var sessionManager
    @Environment(AppSettings.self) private var settings
    @State private var customInput = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label {
                Text("Question")
                    .font(.subheadline.weight(.medium))
            } icon: {
                Image(systemName: "questionmark.circle.fill")
                    .foregroundStyle(.blue)
            }

            if let message = event.message {
                Text(message)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            // Option buttons from tool input
            if let options = extractOptions() {
                ForEach(options, id: \.self) { option in
                    Button {
                        respond(option)
                    } label: {
                        Text(option)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .buttonStyle(.bordered)
                }
            }

            // Free text input
            HStack(spacing: 8) {
                TextField("Type response...", text: $customInput)
                    .textFieldStyle(.roundedBorder)
                    .font(.caption)
                    .onSubmit {
                        guard !customInput.isEmpty else { return }
                        respond(customInput)
                    }

                Button("Send") {
                    guard !customInput.isEmpty else { return }
                    respond(customInput)
                }
                .buttonStyle(.borderedProminent)
                .disabled(customInput.isEmpty)
            }
        }
        .padding(16)
    }

    private func extractOptions() -> [String]? {
        guard let input = event.toolInput,
              let options = input["options"] as? [[String: Any]] else {
            return nil
        }
        return options.compactMap { $0["label"] as? String }
    }

    private func respond(_ text: String) {
        let adapter = TerminalAdapterFactory.create(for: settings.terminalType, event: event)
        sessionManager.respond(text, for: event, using: adapter)
    }
}
