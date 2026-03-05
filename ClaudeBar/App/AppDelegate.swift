import AppKit
import SwiftUI

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var popover: NSPopover!
    private var socketServer: SocketServer!

    let sessionManager = SessionManager()
    let appSettings = AppSettings()

    func applicationDidFinishLaunching(_ notification: Notification) {
        setupStatusItem()
        setupPopover()
        startSocketServer()
        observeEvents()
    }

    func applicationWillTerminate(_ notification: Notification) {
        socketServer?.stop()
    }

    // MARK: - Status Item

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)

        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "bubble.left.fill", accessibilityDescription: "ClaudeBar")
            button.action = #selector(togglePopover)
            button.target = self
        }
    }

    // MARK: - Popover

    private func setupPopover() {
        popover = NSPopover()
        popover.contentSize = NSSize(width: 320, height: 200)
        popover.behavior = .transient
        popover.animates = true
        popover.contentViewController = NSHostingController(
            rootView: PopoverView()
                .environment(sessionManager)
                .environment(appSettings)
        )
    }

    @objc private func togglePopover() {
        guard let button = statusItem.button else { return }

        if popover.isShown {
            popover.performClose(nil)
        } else {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        }
    }

    func showPopover() {
        guard let button = statusItem.button else { return }
        if !popover.isShown {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        }
    }

    // MARK: - Status Icon

    func updateStatusIcon(hasAttention: Bool) {
        guard let button = statusItem.button else { return }

        if hasAttention {
            button.image = NSImage(
                systemSymbolName: "bubble.left.and.exclamationmark.bubble.right.fill",
                accessibilityDescription: "ClaudeBar - Needs Attention"
            )
            button.contentTintColor = .systemOrange
        } else {
            button.image = NSImage(
                systemSymbolName: "bubble.left.fill",
                accessibilityDescription: "ClaudeBar"
            )
            button.contentTintColor = nil
        }
    }

    // MARK: - Socket Server

    private func startSocketServer() {
        socketServer = SocketServer()
        socketServer.start { [weak self] data in
            self?.handleIncomingData(data)
        }
    }

    private func handleIncomingData(_ data: Data) {
        guard let event = EventParser.parse(data) else { return }

        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.sessionManager.handleEvent(event)
            self.updateStatusIcon(hasAttention: true)

            if self.appSettings.autoPopup {
                self.showPopover()
            }

            if self.appSettings.soundEnabled {
                NSSound(named: "Ping")?.play()
            }
        }
    }

    // MARK: - Observe Session Manager

    private func observeEvents() {
        // Observe when events are dismissed/responded to
        sessionManager.onEventDismissed = { [weak self] in
            self?.updateStatusIcon(hasAttention: false)
        }
    }
}
