import SwiftUI
import AppKit

// MARK: – Data models

struct MarketplaceSkin: Decodable, Identifiable {
    let id: String
    let name: String
    let author: String
    let bundled: Bool
    let url: String?
}

private struct MarketplaceManifest: Decodable {
    let sprites: [MarketplaceSkin]
}

// MARK: – Store

@MainActor
final class MarketplaceStore: ObservableObject {
    @Published private(set) var skins: [MarketplaceSkin] = []
    @Published private(set) var downloading: Set<String> = []
    @Published private(set) var failed: Set<String> = []
    @Published private(set) var isLoading = false
    @Published private(set) var loadError: String? = nil

    let renderer: MetalRenderer

    private let manifestURL = URL(string:
        "https://raw.githubusercontent.com/hellov3an/OnekoMac/main/.github/marketplace/manifest.json"
    )!

    init(renderer: MetalRenderer) {
        self.renderer = renderer
    }

    func fetchManifest() async {
        isLoading = true
        loadError = nil
        do {
            let (data, _) = try await URLSession.shared.data(from: manifestURL)
            let manifest  = try JSONDecoder().decode(MarketplaceManifest.self, from: data)
            skins = manifest.sprites
        } catch {
            loadError = error.localizedDescription
        }
        isLoading = false
    }

    func download(_ skin: MarketplaceSkin) {
        guard let urlString = skin.url, let url = URL(string: urlString) else { return }
        downloading.insert(skin.id)
        failed.remove(skin.id)
        renderer.skinManager.downloadSprite(id: skin.id, from: url) { [weak self] success in
            guard let self else { return }
            self.downloading.remove(skin.id)
            if success {
                self.renderer.refreshAvailableSkins()
            } else {
                self.failed.insert(skin.id)
            }
        }
    }

    func isInstalled(_ id: String) -> Bool {
        renderer.skinManager.texture(id: id) != nil
    }
}

// MARK: – Main view

struct MarketplaceView: View {
    @EnvironmentObject var lang: LanguageManager
    @ObservedObject var store: MarketplaceStore

    private let columns = [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        ZStack {
            Color(red: 0.055, green: 0.055, blue: 0.11).ignoresSafeArea()

            VStack(spacing: 0) {
                header
                Divider().opacity(0.3)

                if store.isLoading {
                    Spacer()
                    VStack(spacing: 12) {
                        ProgressView()
                        Text(lang["marketplace.loading"])
                            .font(.callout)
                            .foregroundStyle(.white.opacity(0.5))
                    }
                    Spacer()
                } else if let err = store.loadError {
                    Spacer()
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.largeTitle)
                            .foregroundStyle(.orange)
                        Text(lang["marketplace.error"])
                            .font(.headline)
                            .foregroundStyle(.white)
                        Text(err)
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.4))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                        Button(lang["marketplace.retry"]) {
                            Task { await store.fetchManifest() }
                        }
                        .buttonStyle(.bordered)
                        .tint(.orange)
                    }
                    Spacer()
                } else {
                    ScrollView {
                        LazyVGrid(columns: columns, spacing: 16) {
                            ForEach(store.skins) { skin in
                                skinCard(skin)
                            }
                        }
                        .padding(20)
                    }
                }
            }
        }
        .frame(width: 460, height: 420)
        .task { await store.fetchManifest() }
    }

    // MARK: – Header

    private var header: some View {
        HStack(spacing: 14) {
            Image(systemName: "square.grid.2x2.fill")
                .font(.title2)
                .foregroundStyle(.orange)
            VStack(alignment: .leading, spacing: 2) {
                Text(lang["marketplace.title"])
                    .font(.headline)
                    .foregroundStyle(.white)
                Text(lang["marketplace.subtitle"])
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.45))
            }
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
    }

    // MARK: – Skin card

    private func skinCard(_ skin: MarketplaceSkin) -> some View {
        let installed  = store.isInstalled(skin.id)
        let inProgress = store.downloading.contains(skin.id)
        let hasFailed  = store.failed.contains(skin.id)

        return VStack(spacing: 8) {
            // Preview sprite
            ZStack {
                Circle()
                    .fill(Color.orange.opacity(0.1))
                    .frame(width: 72, height: 72)
                if let img = spritePreview(for: skin.id) {
                    Image(nsImage: img)
                        .interpolation(.none)
                        .frame(width: 52, height: 52)
                } else {
                    Image(systemName: "questionmark.square.dashed")
                        .font(.title2)
                        .foregroundStyle(.white.opacity(0.3))
                }
            }

            Text(skin.name)
                .font(.callout.weight(.semibold))
                .foregroundStyle(.white)

            Text("@\(skin.author)")
                .font(.caption2)
                .foregroundStyle(.white.opacity(0.4))

            // Status / action
            if skin.bundled || installed {
                Text(skin.bundled ? lang["marketplace.bundled"] : lang["marketplace.installed"])
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.green)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(.green.opacity(0.12), in: Capsule())
            } else if inProgress {
                ProgressView()
                    .scaleEffect(0.7)
                    .frame(height: 22)
            } else {
                Button {
                    store.download(skin)
                } label: {
                    Text(hasFailed ? "↺" : lang["marketplace.download"])
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(.orange, in: Capsule())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity)
        .background(.white.opacity(0.04), in: RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(.white.opacity(0.08), lineWidth: 1))
    }

    // MARK: – Sprite preview (idle frame)

    private func spritePreview(for id: String) -> NSImage? {
        guard let url  = SkinManager.gifURL(for: id),
              let data = try? Data(contentsOf: url),
              let src  = CGImageSourceCreateWithData(data as CFData, nil),
              let full = CGImageSourceCreateImageAtIndex(src, 0, nil),
              let crop = full.cropping(to: CGRect(x: 3*32, y: 3*32, width: 32, height: 32))
        else { return nil }
        let img = NSImage(cgImage: crop, size: NSSize(width: 52, height: 52))
        img.cacheMode = .never
        return img
    }
}
