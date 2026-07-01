import AppKit

@MainActor
final class MenuBarController {
    private var statusItem: NSStatusItem!
    private var windowController: SettingsWindowController!
    private weak var renderer: MetalRenderer?

    init(renderer: MetalRenderer, langManager: LanguageManager) {
        self.renderer = renderer
        windowController = SettingsWindowController(renderer: renderer, langManager: langManager)
        setupStatusItem()
    }

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        guard let btn = statusItem.button else { return }
        btn.image = NSImage(systemSymbolName: "pawprint.fill",
                            accessibilityDescription: "OnekoMac")
        btn.imageScaling = .scaleProportionallyDown
        btn.action = #selector(handleClick(_:))
        btn.target = self
        btn.sendAction(on: [.leftMouseUp, .rightMouseUp])
    }

    @objc private func handleClick(_ sender: NSStatusBarButton) {
        guard let event = NSApp.currentEvent else { return }
        if event.type == .rightMouseUp {
            showContextMenu()
        } else {
            windowController.toggle(relativeTo: sender)
        }
    }

    private func showContextMenu() {
        let menu = NSMenu()

        let laserItem = NSMenuItem(
            title: "🔴  Laser Pointer",
            action: #selector(toggleLaser),
            keyEquivalent: ""
        )
        laserItem.target = self
        laserItem.state  = (renderer?.laserActive ?? false) ? .on : .off
        menu.addItem(laserItem)

        menu.addItem(.separator())

        let settingsItem = NSMenuItem(
            title: "Settings",
            action: #selector(openSettings),
            keyEquivalent: ","
        )
        settingsItem.target = self
        menu.addItem(settingsItem)

        menu.addItem(.separator())

        menu.addItem(NSMenuItem(
            title: "Quit OnekoMac",
            action: #selector(NSApplication.terminate(_:)),
            keyEquivalent: "q"
        ))

        // Temporarily assign menu so the button triggers it, then clear.
        statusItem.menu = menu
        statusItem.button?.performClick(nil)
        statusItem.menu = nil
    }

    @objc private func toggleLaser() {
        guard let renderer else { return }
        renderer.setLaserActive(!renderer.laserActive)
    }

    @objc private func openSettings() {
        guard let btn = statusItem.button else { return }
        windowController.toggle(relativeTo: btn)
    }
}
