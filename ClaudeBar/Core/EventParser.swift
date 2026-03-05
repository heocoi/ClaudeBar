import Foundation

// MARK: - Event Model

struct ClaudeEvent: Identifiable {
    let id: UUID
    let sessionId: String
    let hookEventName: String
    let message: String?
    let title: String?
    let notificationType: NotificationType?
    let toolName: String?
    let toolInput: [String: Any]?
    let cwd: String?
    let kittyWindowId: Int?
    let timestamp: Date

    enum NotificationType: String {
        case permissionPrompt = "permission_prompt"
        case idlePrompt = "idle_prompt"
        case elicitationDialog = "elicitation_dialog"
    }
}

// MARK: - Parser

enum EventParser {
    static func parse(_ data: Data) -> ClaudeEvent? {
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return nil
        }

        let hookEventName = json["hook_event_name"] as? String ?? json["hookEventName"] as? String ?? "Unknown"
        let sessionId = json["session_id"] as? String ?? json["sessionId"] as? String ?? UUID().uuidString

        let notificationTypeStr = json["notification_type"] as? String ?? json["notificationType"] as? String
        let notificationType = notificationTypeStr.flatMap { ClaudeEvent.NotificationType(rawValue: $0) }

        // Extract message: try multiple fields
        let message = json["message"] as? String
            ?? json["last_assistant_message"] as? String
            ?? json["lastAssistantMessage"] as? String

        let toolInput = json["tool_input"] as? [String: Any] ?? json["toolInput"] as? [String: Any]

        return ClaudeEvent(
            id: UUID(),
            sessionId: sessionId,
            hookEventName: hookEventName,
            message: message,
            title: json["title"] as? String,
            notificationType: notificationType,
            toolName: json["tool_name"] as? String ?? json["toolName"] as? String,
            toolInput: toolInput,
            cwd: json["cwd"] as? String,
            kittyWindowId: json["kitty_window_id"] as? Int,
            timestamp: Date()
        )
    }
}
