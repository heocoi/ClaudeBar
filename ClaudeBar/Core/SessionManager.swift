import Foundation
import os

private let logger = Logger(subsystem: "com.anhphong.ClaudeBar", category: "SessionManager")

@Observable
final class SessionManager {
    var currentEvent: ClaudeEvent?
    var eventHistory: [ClaudeEvent] = []

    var onEventDismissed: (() -> Void)?

    func handleEvent(_ event: ClaudeEvent) {
        currentEvent = event
        eventHistory.append(event)

        // Keep history bounded
        if eventHistory.count > 50 {
            eventHistory.removeFirst(eventHistory.count - 50)
        }
    }

    func dismissEvent() {
        currentEvent = nil
        onEventDismissed?()
    }

    func respond(_ text: String, for event: ClaudeEvent, using adapter: TerminalAdapter) {
        currentEvent = nil
        onEventDismissed?()

        Task {
            do {
                try await adapter.sendText(text)
                logger.info("Sent '\(text)' to terminal")
            } catch {
                logger.error("Failed to send to terminal: \(error.localizedDescription)")
            }
        }
    }
}
