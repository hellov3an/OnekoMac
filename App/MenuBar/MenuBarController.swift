import AppKit

@MainActor
final class MenuBarController {
    private var statusItem: NSStatusItem!
    private var windowController: SettingsWindowController!

    init(renderer: MetalRenderer, langManager: LanguageManager) {
        windowController = SettingsWindowController(renderer: renderer, langManager: langManager)
        setupStatusItem()
    }

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        guard let btn = statusItem.button else { return }
        btn.image = NSImage(systemSymbolName: "pawprint.fill",
                            accessibilityDescription: "OnekoMac")
        btn.imageScaling = .scaleProportionallyDown
        btn.action = #selector(toggle(_:))
        btn.target = self
        btn.sendAction(on: [.leftMouseUp, .rightMouseUp])
    }

    @objc private func toggle(_ sender: NSStatusBarButton) {
        windowController.toggle(relativeTo: sender)
    }
}
