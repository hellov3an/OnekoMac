import AppKit

// Run on MainActor: AppDelegate and NSApplication require main thread.
MainActor.assumeIsolated {
    let delegate = AppDelegate()
    NSApplication.shared.delegate = delegate
    NSApplication.shared.run()
}
