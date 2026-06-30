import AppKit

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var overlayWindow: OverlayWindow!
    private var renderer: MetalRenderer!
    private var menuBar: MenuBarController!

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

        menuBar = MenuBarController(renderer: renderer)
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { false }
}
