import AppKit
import SwiftUI

/// Floating settings panel — appears below the menu bar icon, stays on top.
final class SettingsWindow: NSPanel {
    init() {
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: 340, height: 380),
            styleMask:   [.titled, .closable, .fullSizeContentView, .nonactivatingPanel],
            backing:     .buffered,
            defer:       false
        )
        title                          = "OnekoMac+"
        titlebarAppearsTransparent     = true
        isMovableByWindowBackground    = true
        level                          = .floating
        isReleasedWhenClosed           = false
        collectionBehavior             = [.canJoinAllSpaces, .fullScreenAuxiliary]
        backgroundColor                = NSColor.windowBackgroundColor
    }

    override var canBecomeKey: Bool { true }

    func show(relativeTo button: NSStatusBarButton) {
        let screenFrame = button.window?.screen?.frame ?? NSScreen.main?.frame ?? .zero
        let winW = frame.width
        let winH = frame.height

        // Convert button origin to screen coordinates.
        let btnScreenOrigin = button.window.map {
            button.convert(NSPoint.zero, to: nil)
                .applying(CGAffineTransform(translationX: $0.frame.origin.x,
                                            y: $0.frame.origin.y))
        } ?? NSPoint.zero

        var x = btnScreenOrigin.x + button.bounds.width / 2 - winW / 2
        var y = btnScreenOrigin.y - winH - 4

        x = min(max(x, screenFrame.minX + 8), screenFrame.maxX - winW - 8)
        y = max(y, screenFrame.minY + 8)

        setFrameOrigin(NSPoint(x: x, y: y))
        makeKeyAndOrderFront(nil)
    }
}

/// Wraps the SwiftUI ControlPanel into the NSPanel.
@MainActor
final class SettingsWindowController {
    private let window = SettingsWindow()
    private let updater = Updater()

    init(renderer: MetalRenderer) {
        let view = SettingsView(renderer: renderer, updater: updater, stats: renderer.catStats)
        window.contentView = NSHostingView(rootView: view)
    }

    func toggle(relativeTo button: NSStatusBarButton) {
        if window.isVisible {
            window.orderOut(nil)
        } else {
            window.show(relativeTo: button)
        }
    }
}
