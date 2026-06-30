import Foundation
import AppKit

@MainActor
final class Updater: ObservableObject {
    enum State: Equatable {
        case idle
        case checking
        case upToDate
        case available(String, URL)   // version, zip asset URL
        case downloading
        case installing
        case error(String)
    }

    @Published private(set) var state: State = .idle

    private let repoAPI = URL(string: "https://api.github.com/repos/hellov3an/OnekoMac/releases/latest")!

    var currentVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    }

    // MARK: – Check for updates

    func checkForUpdates() async {
        state = .checking
        do {
            var req = URLRequest(url: repoAPI)
            req.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
            let (data, _) = try await URLSession.shared.data(for: req)

            struct Asset: Decodable {
                let name: String
                let browser_download_url: String
            }
            struct Release: Decodable {
                let tag_name: String
                let assets: [Asset]
            }

            let release = try JSONDecoder().decode(Release.self, from: data)
            let remote  = release.tag_name.trimmingCharacters(in: .init(charactersIn: "v"))

            guard isNewer(remote, than: currentVersion) else { state = .upToDate; return }

            // Prefer the ZIP asset; fall back to opening the browser
            if let asset = release.assets.first(where: { $0.name.hasSuffix(".zip") }),
               let url   = URL(string: asset.browser_download_url) {
                state = .available(remote, url)
            } else {
                state = .available(remote, URL(string: "https://github.com/hellov3an/OnekoMac/releases/latest")!)
            }
        } catch {
            state = .error(error.localizedDescription)
        }
    }

    // MARK: – Download + replace + relaunch

    func downloadAndInstall(zipURL: URL) async {
        state = .downloading
        do {
            // 1. Download ZIP
            let (zipData, _) = try await URLSession.shared.data(from: zipURL)

            state = .installing

            // 2. Extract to a temp directory
            let fm  = FileManager.default
            let tmp = fm.temporaryDirectory.appendingPathComponent("OnekoMacUpdate-\(UUID().uuidString)")
            try fm.createDirectory(at: tmp, withIntermediateDirectories: true)
            defer { try? fm.removeItem(at: tmp) }

            let zipFile = tmp.appendingPathComponent("update.zip")
            try zipData.write(to: zipFile)

            try shell("/usr/bin/unzip", ["-o", zipFile.path, "-d", tmp.path])

            // 3. Verify the extracted .app exists
            let newApp = tmp.appendingPathComponent("OnekoMac.app")
            guard fm.fileExists(atPath: newApp.path) else {
                state = .error("Archive invalid"); return
            }

            // 4. Strip quarantine so macOS doesn't block the replacement
            try? shell("/usr/bin/xattr", ["-cr", newApp.path])

            // 5. Write a tiny bash script that:
            //    • waits for this process to exit
            //    • replaces the bundle
            //    • strips quarantine on the installed copy
            //    • reopens the app
            let target = Bundle.main.bundleURL.path
            let script = """
            #!/bin/bash
            sleep 1.5
            rm -rf '\(target)'
            cp -R '\(newApp.path)' '\(target)'
            /usr/bin/xattr -cr '\(target)'
            open '\(target)'
            """

            let scriptFile = fm.temporaryDirectory.appendingPathComponent("onekomac_install.sh")
            try script.write(to: scriptFile, atomically: true, encoding: .utf8)
            try fm.setAttributes([.posixPermissions: 0o755], ofItemAtPath: scriptFile.path)

            // 6. Launch the installer script (detached), then quit
            let proc = Process()
            proc.executableURL = URL(fileURLWithPath: "/bin/bash")
            proc.arguments     = [scriptFile.path]
            proc.standardOutput = FileHandle.nullDevice
            proc.standardError  = FileHandle.nullDevice
            try proc.run()

            NSApplication.shared.terminate(nil)

        } catch {
            state = .error(error.localizedDescription)
        }
    }

    // MARK: – Helpers

    @discardableResult
    private func shell(_ exe: String, _ args: [String]) throws -> Int32 {
        let p = Process()
        p.executableURL = URL(fileURLWithPath: exe)
        p.arguments     = args
        try p.run()
        p.waitUntilExit()
        return p.terminationStatus
    }

    private func isNewer(_ remote: String, than local: String) -> Bool {
        let r = remote.split(separator: ".").compactMap { Int($0) }
        let l = local.split(separator: ".").compactMap  { Int($0) }
        for i in 0..<max(r.count, l.count) {
            let rv = i < r.count ? r[i] : 0
            let lv = i < l.count ? l[i] : 0
            if rv != lv { return rv > lv }
        }
        return false
    }
}
