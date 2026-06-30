import AppKit
import os.lock

/// Thread-safe global mouse position tracker.
/// Coordinates: screen POINTS, TOP-LEFT origin.
/// Uses NSEvent global monitor — no Accessibility permission needed.
final class MouseTracker {
    private var _x: Float = 0
    private var _y: Float = 0
    private var _lock = os_unfair_lock()

    var position: (x: Float, y: Float) {
        os_unfair_lock_lock(&_lock)
        let x = _x; let y = _y
        os_unfair_lock_unlock(&_lock)
        return (x, y)
    }

    init() {
        // Seed with current position so the cat doesn't rush from (0,0) on start.
        sampleMouseLocation()

        // Fires for events destined to other apps (no special permission needed).
        // Our overlay ignores mouse events so all cursor activity reaches this monitor.
        NSEvent.addGlobalMonitorForEvents(
            matching: [.mouseMoved, .leftMouseDragged, .rightMouseDragged, .otherMouseDragged]
        ) { [weak self] _ in
            self?.sampleMouseLocation()
        }
    }

    private func sampleMouseLocation() {
        let p = NSEvent.mouseLocation          // AppKit: bottom-left origin
        guard let screen = NSScreen.main else { return }
        let h = Float(screen.frame.height)
        os_unfair_lock_lock(&_lock)
        _x = Float(p.x)
        _y = h - Float(p.y)                   // flip to top-left origin
        os_unfair_lock_unlock(&_lock)
    }
}
