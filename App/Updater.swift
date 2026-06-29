import Foundation

@MainActor
final class Updater: ObservableObject {
    enum State: Equatable {
        case idle, checking, upToDate, available(String, URL), error(String)
    }

    @Published private(set) var state: State = .idle

    private let repoAPI = URL(string: "https://api.github.com/repos/hellov3an/OnekoMac/releases/latest")!
    private let releasesPage = URL(string: "https://github.com/hellov3an/OnekoMac/releases/latest")!

    var currentVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    }

    func checkForUpdates() async {
        state = .checking
        do {
            var req = URLRequest(url: repoAPI)
            req.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
            let (data, _) = try await URLSession.shared.data(for: req)

            struct Release: Decodable {
                let tag_name: String
                let html_url: String
            }
            let release = try JSONDecoder().decode(Release.self, from: data)
            let remoteVersion = release.tag_name.trimmingCharacters(in: .init(charactersIn: "v"))
            let downloadURL = URL(string: release.html_url) ?? releasesPage

            if isNewer(remoteVersion, than: currentVersion) {
                state = .available(remoteVersion, downloadURL)
            } else {
                state = .upToDate
            }
        } catch {
            state = .error("Impossible de vérifier les mises à jour")
        }
    }

    /// Simple semver comparison: "1.2.3" > "1.1.0" → true
    private func isNewer(_ remote: String, than local: String) -> Bool {
        let r = remote.split(separator: ".").compactMap { Int($0) }
        let l = local.split(separator: ".").compactMap { Int($0) }
        for i in 0..<max(r.count, l.count) {
            let rv = i < r.count ? r[i] : 0
            let lv = i < l.count ? l[i] : 0
            if rv != lv { return rv > lv }
        }
        return false
    }
}
