import AppKit

/// Fullscreen transparent overlay spanning ALL connected screens.
/// Click-through: mouse events pass through to the app below.
final class OverlayWindow: NSWindow {

    /// Union of all screen frames in AppKit coordinates (bottom-left origin).
    static func unionFrame() -> NSRect {
        NSScreen.screens.reduce(.null) { $0.union($1.frame) }
    }

    init() {
        let frame = OverlayWindow.unionFrame()
        super.init(contentRect: frame, styleMask: [.borderless], backing: .buffered, defer: false)
        setFrame(frame, display: false)
        level                = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.overlayWindow)) + 1)
        backgroundColor      = .clear
        isOpaque             = false
        hasShadow            = false
        ignoresMouseEvents   = true
        collectionBehavior   = [.canJoinAllSpaces, .stationary, .fullScreenAuxiliary, .ignoresCycle]
        isReleasedWhenClosed = false

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(screensChanged),
            name: NSApplication.didChangeScreenParametersNotification,
            object: nil
        )
    }

    @objc private func screensChanged() {
        setFrame(OverlayWindow.unionFrame(), display: false)
    }

    override var canBecomeKey: Bool  { false }
    override var canBecomeMain: Bool { false }
}
