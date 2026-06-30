import AppKit
import SwiftUI

final class WrappedWindow: NSWindow {
    init() {
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: 520, height: 480),
            styleMask: [.titled, .closable, .fullSizeContentView],
            backing: .buffered,
            defer: false
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
final class WrappedWindowController {
    private let window = WrappedWindow()
    private let renderer: MetalRenderer
    private let langManager: LanguageManager

    init(renderer: MetalRenderer, langManager: LanguageManager) {
        self.renderer    = renderer
        self.langManager = langManager
    }

    func show() {
        let view = WrappedView(
            stats:   renderer.catStats,
            skinID:  renderer.currentSkinID,
            onClose: { [weak self] in self?.window.close() }
        )
        .environmentObject(langManager)

        window.contentView = NSHostingView(rootView: view)
        window.center()
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}
