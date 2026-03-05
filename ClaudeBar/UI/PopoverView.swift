import SwiftUI

struct PopoverView: View {
    @Environment(SessionManager.self) private var sessionManager
    @Environment(AppSettings.self) private var settings

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Image(systemName: "bubble.left.fill")
                    .foregroundStyle(.orange)
                Text("ClaudeBar")
                    .font(.headline)
                Spacer()
                if sessionManager.currentEvent != nil {
                    Button {
                        sessionManager.dismissEvent()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)

            Divider()

            // Content
            if let event = sessionManager.currentEvent {
                eventView(for: event)
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
            } else {
                idleView
            }
        }
        .frame(width: 320)
        .animation(.easeInOut(duration: 0.2), value: sessionManager.currentEvent?.id)
    }

    @ViewBuilder
    private func eventView(for event: ClaudeEvent) -> some View {
        switch event.notificationType {
        case .permissionPrompt:
            PermissionView(event: event)
        case .elicitationDialog:
            QuestionView(event: event)
        case .idlePrompt:
            InputView(event: event, prompt: event.message ?? "Claude is waiting for input")
        case nil:
            // Stop event or unknown — show message
            if event.hookEventName == "Stop" {
                stopView(event: event)
            } else {
                InputView(event: event, prompt: event.message ?? "Event received")
            }
        }
    }

    private func stopView(event: ClaudeEvent) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Task Completed", systemImage: "checkmark.circle.fill")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.green)

            if let message = event.message {
                Text(message)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(4)
            }

            Button("Dismiss") {
                sessionManager.dismissEvent()
            }
            .buttonStyle(.borderedProminent)
            .frame(maxWidth: .infinity)
        }
        .padding(16)
    }

    private var idleView: some View {
        VStack(spacing: 8) {
            Image(systemName: "checkmark.circle")
                .font(.title)
                .foregroundStyle(.secondary)
            Text("No pending events")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(24)
    }
}
