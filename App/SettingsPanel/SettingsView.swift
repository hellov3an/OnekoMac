import SwiftUI
import AppKit

// MARK: – Skin preview image (idle frame cropped from the GIF atlas)

struct SkinPreview: View {
    let skinID: String
    let isSelected: Bool

    var body: some View {
        VStack(spacing: 4) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(isSelected
                          ? Color.accentColor.opacity(0.18)
                          : Color.secondary.opacity(0.08))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .strokeBorder(isSelected ? Color.accentColor : Color.clear, lineWidth: 2)
                    )
                    .frame(width: 56, height: 56)

                if let img = idleImage(for: skinID) {
                    Image(nsImage: img)
                        .interpolation(.none)
                        .frame(width: 48, height: 48)
                }
            }
            Text(skinID.capitalized)
                .font(.caption2)
                .foregroundStyle(isSelected ? .primary : .secondary)
        }
    }

    // Crop the idle frame (col=3, row=3 in the 8×8 grid) from the GIF.
    private func idleImage(for id: String) -> NSImage? {
        guard let url = Bundle.main.url(forResource: "oneko-\(id)",
                                         withExtension: "gif",
                                         subdirectory: "Sprites"),
              let data = try? Data(contentsOf: url),
              let src  = CGImageSourceCreateWithData(data as CFData, nil),
              let full = CGImageSourceCreateImageAtIndex(src, 0, nil) else { return nil }

        // Idle sprite: col=3, row=3 — top-left origin, each cell is 32×32 px.
        let col = 3, row = 3, cellSize = 32
        let rect = CGRect(x: col * cellSize, y: row * cellSize, width: cellSize, height: cellSize)
        guard let cropped = full.cropping(to: rect) else { return nil }

        // Scale 32px → 48pt for the preview tile (pixel art scaling).
        let img = NSImage(cgImage: cropped, size: NSSize(width: 48, height: 48))
        img.cacheMode = .never
        return img
    }
}

// MARK: – Main settings view

struct SettingsView: View {
    @ObservedObject var renderer: MetalRenderer
    @ObservedObject var updater: Updater

    var body: some View {
        VStack(spacing: 0) {
            titleBar
            Divider()
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    skinSection
                    Divider()
                    updatesSection
                    Divider()
                    debugSection
                }
                .padding(20)
            }
            Divider()
            bottomBar
        }
        .frame(width: 340)
    }

    // MARK: – Title bar

    var titleBar: some View {
        HStack(spacing: 10) {
            Image(systemName: "pawprint.fill")
                .font(.title2)
                .foregroundStyle(.orange)
            VStack(alignment: .leading, spacing: 1) {
                Text("OnekoMac+")
                    .font(.headline)
                Text("v\(updater.currentVersion)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Text(String(format: "%.0f fps", renderer.stats.fps))
                .font(.caption.monospacedDigit())
                .padding(.horizontal, 7)
                .padding(.vertical, 3)
                .background(.quaternary, in: Capsule())
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
        .padding(.bottom, 12)
    }

    // MARK: – Skin section

    var skinSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Skin", systemImage: "paintbrush.fill")
                .font(.subheadline).bold()

            HStack(spacing: 8) {
                ForEach(SkinManager.skinIDs, id: \.self) { id in
                    SkinPreview(skinID: id, isSelected: renderer.currentSkinID == id)
                        .onTapGesture { renderer.setSkin(id) }
                        .animation(.easeInOut(duration: 0.15), value: renderer.currentSkinID)
                }
            }
        }
    }

    // MARK: – Updates section

    var updatesSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Mises à jour", systemImage: "arrow.down.circle.fill")
                .font(.subheadline).bold()

            HStack(spacing: 10) {
                updateStatusView
                Spacer()
                Button("Vérifier") {
                    Task { await updater.checkForUpdates() }
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .disabled(updater.state == .checking)
            }

            if case .available(let version, let url) = updater.state {
                HStack(spacing: 6) {
                    Image(systemName: "arrow.down.circle.fill").foregroundStyle(.green)
                    Text("v\(version) disponible")
                        .fontWeight(.medium)
                    Spacer()
                    Link("Télécharger", destination: url)
                        .font(.callout)
                }
                .padding(8)
                .background(Color.green.opacity(0.1), in: RoundedRectangle(cornerRadius: 8))
            }
        }
    }

    @ViewBuilder
    var updateStatusView: some View {
        switch updater.state {
        case .idle:
            Text("Jamais vérifié")
                .foregroundStyle(.secondary)
        case .checking:
            HStack(spacing: 6) {
                ProgressView().scaleEffect(0.7)
                Text("Vérification…")
            }
        case .upToDate:
            HStack(spacing: 6) {
                Image(systemName: "checkmark.circle.fill").foregroundStyle(.green)
                Text("À jour")
            }
        case .available(let v, _):
            HStack(spacing: 6) {
                Image(systemName: "exclamationmark.circle.fill").foregroundStyle(.orange)
                Text("v\(v) disponible")
            }
        case .error(let msg):
            HStack(spacing: 6) {
                Image(systemName: "xmark.circle.fill").foregroundStyle(.red)
                Text(msg).foregroundStyle(.red)
            }
        }
    }

    // MARK: – Debug section

    var debugSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Label("Debug", systemImage: "chart.bar.fill")
                .font(.subheadline).bold()
            HStack {
                debugStat("FPS",    String(format: "%.0f", renderer.stats.fps))
                Spacer()
                debugStat("GPU ms", String(format: "%.2f", renderer.stats.gpuMs))
            }
        }
    }

    func debugStat(_ label: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label).font(.caption).foregroundStyle(.secondary)
            Text(value).font(.system(.callout, design: .monospaced)).fontWeight(.semibold)
        }
    }

    // MARK: – Bottom bar

    var bottomBar: some View {
        HStack {
            Link("GitHub", destination: URL(string: "https://github.com/hellov3an/OnekoMac")!)
                .font(.caption)
                .foregroundStyle(.secondary)
            Spacer()
            Button("Quitter OnekoMac") {
                NSApplication.shared.terminate(nil)
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
            .tint(.red)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
    }
}
