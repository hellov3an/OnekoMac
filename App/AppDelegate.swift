import AppKit

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var overlayWindow: OverlayWindow!
    private var renderer: MetalRenderer!
    private var menuBar: MenuBarController!
    private var langManager = LanguageManager()
    private var onboardingController: OnboardingWindowController?

    func applicationWillFinishLaunching(_ notification: Notification) {
        let running = NSRunningApplication.runningApplications(
            withBundleIdentifier: Bundle.main.bundleIdentifier ?? ""
        )
        if running.count > 1 {
            // Another instance is already running — bring it forward and exit.
            running.first(where: { $0 != NSRunningApplication.current })?.activate(options: .activateIgnoringOtherApps)
            NSApp.terminate(nil)
        }
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)

        do { renderer = try MetalRenderer() }
        catch { fatalError("Metal init failed: \(error)") }

        overlayWindow = OverlayWindow()
        let union = OverlayWindow.unionFrame()
        renderer.view.frame = NSRect(origin: .zero, size: union.size)
        renderer.view.autoresizingMask = [.width, .height]
        let vc = NSViewController()
        vc.view = renderer.view
        overlayWindow.contentViewController = vc
        overlayWindow.orderFrontRegardless()

        menuBar = MenuBarController(renderer: renderer, langManager: langManager)

        if !UserDefaults.standard.bool(forKey: "onboarding_completed") {
            onboardingController = OnboardingWindowController(
                renderer: renderer,
                langManager: langManager
            )
            onboardingController?.show()
        }
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { false }
}
