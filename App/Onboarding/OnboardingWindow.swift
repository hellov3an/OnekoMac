import AppKit
import SwiftUI

// MARK: – Window

final class OnboardingWindow: NSWindow {
    init() {
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: 520, height: 480),
            styleMask: [.titled, .closable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        titlebarAppearsTransparent = true
        titleVisibility            = .hidden
        isMovableByWindowBackground = true
        backgroundColor            = NSColor(red: 0.055, green: 0.055, blue: 0.11, alpha: 1)
        isReleasedWhenClosed       = false
        level                      = .floating
    }

    override var canBecomeKey: Bool { true }
}

// MARK: – Controller

@MainActor
final class OnboardingWindowController {
    private let window = OnboardingWindow()

    init(renderer: MetalRenderer, langManager: LanguageManager) {
        let view = OnboardingView(renderer: renderer, onFinish: { [weak self] in
            self?.finish()
        })
        .environmentObject(langManager)

        window.contentView = NSHostingView(rootView: view)
    }

    func show() {
        window.center()
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    private func finish() {
        UserDefaults.standard.set(true, forKey: "onboarding_completed")
        window.close()
    }
}
