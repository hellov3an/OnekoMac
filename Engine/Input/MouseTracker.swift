import AppKit
import os.lock

/// Thread-safe global mouse position tracker.
/// Coordinates: simulation space — top-left of the union of all screens, Y down.
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
        sampleMouseLocation()   // seed so cat doesn't rush from (0,0) at startup

        NSEvent.addGlobalMonitorForEvents(
            matching: [.mouseMoved, .leftMouseDragged, .rightMouseDragged, .otherMouseDragged]
        ) { [weak self] _ in
            self?.sampleMouseLocation()
        }
    }

    private func sampleMouseLocation() {
        let p     = NSEvent.mouseLocation              // AppKit: bottom-left of primary, Y up
        let union = NSScreen.screens.reduce(NSRect.null) { $0.union($1.frame) }
        os_unfair_lock_lock(&_lock)
        // Convert to simulation space: top-left of the union rect, Y down.
        _x = Float(p.x - union.minX)
        _y = Float(union.maxY - p.y)
        os_unfair_lock_unlock(&_lock)
    }
}
