import Foundation
import os

private let logger = Logger(subsystem: "com.anhphong.ClaudeBar", category: "KittyAdapter")

struct KittyAdapter: TerminalAdapter {
    let windowId: Int?

    init(windowId: Int? = nil) {
        self.windowId = windowId
    }

    static var isAvailable: Bool {
        FileManager.default.isExecutableFile(atPath: "/opt/homebrew/bin/kitten")
            || FileManager.default.isExecutableFile(atPath: "/usr/local/bin/kitten")
    }

    private var matchArg: String {
        if let windowId {
            return "id:\(windowId)"
        }
        return "recent:0"
    }

    func sendText(_ text: String) async throws {
        guard let socketPath = Self.kittySocketPath else {
            logger.error("No kitty socket found")
            throw TerminalError.sendFailed("No kitty socket found. Ensure listen_on is set in kitty.conf and kitty is restarted.")
        }

        logger.info("Sending text to kitty via \(socketPath), match \(self.matchArg): \(text)")

        // Send text
        let sendText = Process()
        sendText.executableURL = URL(fileURLWithPath: Self.kittenPath)
        sendText.arguments = ["@", "--to", "unix:\(socketPath)", "send-text", "--match", matchArg, text]

        let pipe = Pipe()
        sendText.standardOutput = pipe
        sendText.standardError = pipe

        try sendText.run()
        sendText.waitUntilExit()

        if sendText.terminationStatus != 0 {
            let errorData = pipe.fileHandleForReading.readDataToEndOfFile()
            let errorMsg = String(data: errorData, encoding: .utf8) ?? "Unknown error"
            logger.error("kitten send-text failed: \(errorMsg)")
            throw TerminalError.sendFailed(errorMsg)
        }

        // Send Enter key
        let sendKey = Process()
        sendKey.executableURL = URL(fileURLWithPath: Self.kittenPath)
        sendKey.arguments = ["@", "--to", "unix:\(socketPath)", "send-key", "--match", matchArg, "Return"]
        try sendKey.run()
        sendKey.waitUntilExit()

        logger.info("Text sent successfully")
    }

    func focusWindow() async throws {
        guard let socketPath = Self.kittySocketPath else { return }

        let process = Process()
        process.executableURL = URL(fileURLWithPath: Self.kittenPath)
        process.arguments = ["@", "--to", "unix:\(socketPath)", "focus-window"]
        try process.run()
        process.waitUntilExit()
    }

    // Find kitty socket: /tmp/kitty-{pid}
    private static var kittySocketPath: String? {
        let fm = FileManager.default
        if let items = try? fm.contentsOfDirectory(atPath: "/tmp") {
            for item in items where item.hasPrefix("kitty-") {
                let path = "/tmp/\(item)"
                var isDir: ObjCBool = false
                // Unix sockets show as non-directory entries
                if fm.fileExists(atPath: path, isDirectory: &isDir), !isDir.boolValue {
                    return path
                }
            }
        }
        return nil
    }

    private static var kittenPath: String {
        if FileManager.default.isExecutableFile(atPath: "/opt/homebrew/bin/kitten") {
            return "/opt/homebrew/bin/kitten"
        }
        return "/usr/local/bin/kitten"
    }
}

enum TerminalError: LocalizedError {
    case sendFailed(String)

    var errorDescription: String? {
        switch self {
        case .sendFailed(let msg):
            "Failed to send text to terminal: \(msg)"
        }
    }
}
