import CoreVideo
import AppKit

/// Drives the render loop via CVDisplayLink.
/// Callback fires on a high-priority display thread, NOT the main thread.
final class CVDisplayLinkManager: NSObject {
    private var displayLink: CVDisplayLink?
    private var callback: ((Double) -> Void)?

    private var lastTimestamp: CVTimeStamp?

    var isRunning: Bool {
        guard let dl = displayLink else { return false }
        return CVDisplayLinkIsRunning(dl)
    }

    /// `tick` receives delta-time in seconds.
    func start(tick: @escaping (Double) -> Void) {
        self.callback = tick

        CVDisplayLinkCreateWithActiveCGDisplays(&displayLink)
        guard let dl = displayLink else {
            Log.engine.error("Failed to create CVDisplayLink")
            return
        }

        CVDisplayLinkSetOutputHandler(dl) { [weak self] _, inNow, _, _, _ -> CVReturn in
            guard let self else { return kCVReturnSuccess }
            let dt = self.computeDt(inNow.pointee)
            self.callback?(dt)
            return kCVReturnSuccess
        }

        CVDisplayLinkStart(dl)
        Log.engine.info("CVDisplayLink started")

        // Re-attach when active screen changes (e.g. window moved to different display).
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(screenDidChange),
            name: NSApplication.didChangeScreenParametersNotification,
            object: nil
        )
    }

    func stop() {
        guard let dl = displayLink, CVDisplayLinkIsRunning(dl) else { return }
        CVDisplayLinkStop(dl)
    }

    @objc private func screenDidChange() {
        // Rebind to the display the app's key window is on.
        guard let dl = displayLink else { return }
        let display = NSScreen.main.flatMap {
            $0.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? CGDirectDisplayID
        } ?? CGMainDisplayID()
        CVDisplayLinkSetCurrentCGDisplay(dl, display)
    }

    // Returns dt in seconds, capped to avoid spiral-of-death.
    private func computeDt(_ now: CVTimeStamp) -> Double {
        defer { lastTimestamp = now }
        guard let last = lastTimestamp else { return 1.0 / 120.0 }
        let delta = Double(now.videoTime - last.videoTime)
            / Double(now.videoTimeScale)
        return min(delta, 0.1)
    }
}
