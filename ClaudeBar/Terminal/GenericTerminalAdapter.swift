import Foundation

struct GenericTerminalAdapter: TerminalAdapter {
    let terminalType: TerminalType

    static var isAvailable: Bool { true }

    func sendText(_ text: String) async throws {
        let escaped = text
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")

        let script: String
        switch terminalType {
        case .iterm:
            script = """
            tell application "iTerm2"
                tell current session of current window
                    write text "\(escaped)"
                end tell
            end tell
            """
        case .terminal:
            script = """
            tell application "Terminal"
                do script "\(escaped)" in front window
            end tell
            """
        case .wezterm:
            // WezTerm uses CLI
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/usr/local/bin/wezterm")
            process.arguments = ["cli", "send-text", "--no-paste", text + "\n"]
            try process.run()
            process.waitUntilExit()
            return
        case .kitty:
            return // Handled by KittyAdapter
        }

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
        process.arguments = ["-e", script]
        try process.run()
        process.waitUntilExit()
    }

    func focusWindow() async throws {
        let appName: String
        switch terminalType {
        case .iterm: appName = "iTerm2"
        case .terminal: appName = "Terminal"
        case .wezterm: appName = "WezTerm"
        case .kitty: return
        }

        let script = """
        tell application "\(appName)"
            activate
        end tell
        """
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
        process.arguments = ["-e", script]
        try process.run()
        process.waitUntilExit()
    }
}
