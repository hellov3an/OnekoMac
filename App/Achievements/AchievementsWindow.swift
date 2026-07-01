import AppKit
import SwiftUI

final class AchievementsWindow: NSPanel {
    init() {
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: 420, height: 540),
            styleMask:   [.titled, .closable, .fullSizeContentView, .nonactivatingPanel],
            backing:     .buffered,
            defer:       false
        )
        title                      = "Achievements"
        titlebarAppearsTransparent = true
        isMovableByWindowBackground = true
        level                      = .floating
        isReleasedWhenClosed       = false
        collectionBehavior         = [.canJoinAllSpaces, .fullScreenAuxiliary]
        backgroundColor            = NSColor(red: 0.055, green: 0.055, blue: 0.11, alpha: 1)
    }

    override var canBecomeKey: Bool { true }

    func show() {
        if let screen = NSScreen.main {
            let x = screen.frame.midX - frame.width / 2
            let y = screen.frame.midY - frame.height / 2
            setFrameOrigin(NSPoint(x: x, y: y))
        }
        makeKeyAndOrderFront(nil)
    }
}

@MainActor
final class AchievementsWindowController {
    private let window: AchievementsWindow

    init(manager: AchievementManager) {
        window = AchievementsWindow()
        let view = AchievementsView(manager: manager)
        window.contentView = NSHostingView(rootView: view)
    }

    func show() {
        if window.isVisible {
            window.orderFront(nil)
        } else {
            window.show()
        }
    }
}
