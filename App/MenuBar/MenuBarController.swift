import AppKit
import SwiftUI

@MainActor
final class MenuBarController {
    private var statusItem: NSStatusItem!
    private let renderer: MetalRenderer
    private var popover: NSPopover?

    init(renderer: MetalRenderer) {
        self.renderer = renderer
        setupStatusItem()
    }

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        guard let btn = statusItem.button else { return }
        btn.image = NSImage(systemSymbolName: "pawprint.fill",
                            accessibilityDescription: "OnekoMac")
        btn.imageScaling = .scaleProportionallyDown
        btn.action = #selector(toggle)
        btn.target = self
    }

    @objc private func toggle() {
        if let pop = popover, pop.isShown { pop.performClose(nil); return }
        let pop = NSPopover()
        pop.contentSize   = CGSize(width: 260, height: 280)
        pop.behavior      = .transient
        pop.animates      = true
        pop.contentViewController = NSHostingController(
            rootView: ControlPanel(renderer: renderer)
        )
        pop.show(relativeTo: statusItem.button!.bounds,
                 of: statusItem.button!,
                 preferredEdge: .minY)
        self.popover = pop
    }
}
