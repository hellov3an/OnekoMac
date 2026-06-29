import AppKit

/// Fullscreen transparent overlay window that sits above all other windows.
/// Click-through: mouse events pass through to the app below.
final class OverlayWindow: NSWindow {
    init(screen: NSScreen) {
        super.init(
            contentRect: screen.frame,
            styleMask:   [.borderless],
            backing:     .buffered,
            defer:       false
        )
        setFrameOrigin(screen.frame.origin)
        level                   = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.overlayWindow)) + 1)
        backgroundColor         = .clear
        isOpaque                = false
        hasShadow               = false
        ignoresMouseEvents      = true    // click-through
        collectionBehavior      = [.canJoinAllSpaces, .stationary, .fullScreenAuxiliary, .ignoresCycle]
        isReleasedWhenClosed    = false
    }

    override var canBecomeKey: Bool  { false }
    override var canBecomeMain: Bool { false }
}
