import Foundation

@Observable
final class AppSettings {
    var terminalType: TerminalType {
        didSet { UserDefaults.standard.set(terminalType.rawValue, forKey: "terminalType") }
    }

    var autoPopup: Bool {
        didSet { UserDefaults.standard.set(autoPopup, forKey: "autoPopup") }
    }

    var soundEnabled: Bool {
        didSet { UserDefaults.standard.set(soundEnabled, forKey: "soundEnabled") }
    }

    init() {
        let defaults = UserDefaults.standard

        if let raw = defaults.string(forKey: "terminalType"),
           let type = TerminalType(rawValue: raw) {
            self.terminalType = type
        } else {
            self.terminalType = .kitty
        }

        // Register defaults
        defaults.register(defaults: [
            "autoPopup": true,
            "soundEnabled": true,
        ])

        self.autoPopup = defaults.bool(forKey: "autoPopup")
        self.soundEnabled = defaults.bool(forKey: "soundEnabled")
    }
}
