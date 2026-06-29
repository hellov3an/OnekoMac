import CoreGraphics
import AppKit
import os.lock

/// Thread-safe global mouse position tracker.
/// Coordinates: screen POINTS, TOP-LEFT origin (matching CGEvent raw coords).
final class MouseTracker {
    private var _x: Float = 0
    private var _y: Float = 0
    private var _lock = os_unfair_lock()

    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?

    var position: (x: Float, y: Float) {
        os_unfair_lock_lock(&_lock)
        let x = _x; let y = _y
        os_unfair_lock_unlock(&_lock)
        return (x, y)
    }

    init() {
        startEventTap()
    }

    deinit { stop() }

    private func startEventTap() {
        let mask = CGEventMask(1 << CGEventType.mouseMoved.rawValue)
            | CGEventMask(1 << CGEventType.leftMouseDragged.rawValue)
            | CGEventMask(1 << CGEventType.rightMouseDragged.rawValue)
            | CGEventMask(1 << CGEventType.otherMouseDragged.rawValue)

        guard let tap = CGEvent.tapCreate(
            tap: .cghidEventTap,
            place: .headInsertEventTap,
            options: .listenOnly,
            eventsOfInterest: mask,
            callback: { _, _, event, refcon -> Unmanaged<CGEvent>? in
                guard let refcon else { return nil }
                let tracker = Unmanaged<MouseTracker>.fromOpaque(refcon).takeUnretainedValue()
                let loc = event.location  // top-left origin, points
                os_unfair_lock_lock(&tracker._lock)
                tracker._x = Float(loc.x)
                tracker._y = Float(loc.y)
                os_unfair_lock_unlock(&tracker._lock)
                return nil
            },
            userInfo: Unmanaged.passUnretained(self).toOpaque()
        ) else {
            Log.input.warning("CGEventTap failed — using NSEvent fallback")
            startFallback()
            return
        }

        eventTap = tap
        let src = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        runLoopSource = src
        CFRunLoopAddSource(CFRunLoopGetMain(), src, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)
        Log.input.info("CGEventTap active")
    }

    private func startFallback() {
        NSEvent.addGlobalMonitorForEvents(matching: [.mouseMoved, .leftMouseDragged]) { [weak self] _ in
            guard let self else { return }
            let p = NSEvent.mouseLocation
            guard let screen = NSScreen.main else { return }
            let h = Float(screen.frame.height)
            os_unfair_lock_lock(&self._lock)
            self._x = Float(p.x)
            self._y = h - Float(p.y)   // flip from NSScreen bottom-left to top-left
            os_unfair_lock_unlock(&self._lock)
        }
    }

    func stop() {
        guard let tap = eventTap else { return }
        CGEvent.tapEnable(tap: tap, enable: false)
        if let src = runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetMain(), src, .commonModes)
        }
    }
}
