import AppKit
import SwiftUI

final class MarketplaceWindow: NSWindow {
    init() {
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: 460, height: 420),
            styleMask:   [.titled, .closable, .fullSizeContentView],
            backing:     .buffered,
            defer:       false
        )
        titlebarAppearsTransparent  = true
        titleVisibility             = .hidden
        isMovableByWindowBackground = true
        backgroundColor             = NSColor(red: 0.055, green: 0.055, blue: 0.11, alpha: 1)
        isReleasedWhenClosed        = false
        level                       = .floating
    }

    override var canBecomeKey: Bool { true }
}

@MainActor
final class MarketplaceWindowController {
    private let window = MarketplaceWindow()
    private let store: MarketplaceStore

    init(renderer: MetalRenderer, langManager: LanguageManager) {
        store = MarketplaceStore(renderer: renderer)
        let view = MarketplaceView(store: store)
            .environmentObject(langManager)
        window.contentView = NSHostingView(rootView: view)
    }

    func show() {
        window.center()
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}
