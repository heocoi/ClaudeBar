import Foundation

protocol TerminalAdapter {
    func sendText(_ text: String) async throws
    func focusWindow() async throws
    static var isAvailable: Bool { get }
}

enum TerminalType: String, CaseIterable, Identifiable {
    case kitty
    case iterm
    case terminal
    case wezterm

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .kitty: "Kitty"
        case .iterm: "iTerm2"
        case .terminal: "Terminal.app"
        case .wezterm: "WezTerm"
        }
    }
}

enum TerminalAdapterFactory {
    static func create(for type: TerminalType, event: ClaudeEvent? = nil) -> TerminalAdapter {
        switch type {
        case .kitty:
            KittyAdapter(windowId: event?.kittyWindowId)
        case .iterm, .terminal, .wezterm:
            GenericTerminalAdapter(terminalType: type)
        }
    }
}
