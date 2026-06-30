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

    private func idleImage(for id: String) -> NSImage? {
        guard let url = Bundle.main.url(forResource: "oneko-\(id)",
                                         withExtension: "gif",
                                         subdirectory: "Sprites"),
              let data = try? Data(contentsOf: url),
              let src  = CGImageSourceCreateWithData(data as CFData, nil),
              let full = CGImageSourceCreateImageAtIndex(src, 0, nil) else { return nil }

        let rect = CGRect(x: 3 * 32, y: 3 * 32, width: 32, height: 32)
        guard let cropped = full.cropping(to: rect) else { return nil }
        let img = NSImage(cgImage: cropped, size: NSSize(width: 48, height: 48))
        img.cacheMode = .never
        return img
    }
}

// MARK: – Main settings view

struct SettingsView: View {
    @ObservedObject var renderer: MetalRenderer
    @ObservedObject var updater: Updater
    @ObservedObject var stats: CatStats
    @EnvironmentObject var lang: LanguageManager
    let onShowWrapped: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            titleBar
            Divider()
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    skinSection
                    Divider()
                    wrappedSection
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
                Text("OnekoMac")
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
            Label(lang["settings.skin"], systemImage: "paintbrush.fill")
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

    // MARK: – Wrapped stats

    var wrappedSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Wrapped CTA button
            Button { onShowWrapped() } label: {
                HStack(spacing: 10) {
                    Image(systemName: "sparkles")
                    Text(lang["wrapped.btn"])
                    Spacer()
                    Image(systemName: "chevron.right").font(.caption.weight(.semibold))
                }
                .font(.callout.weight(.semibold))
                .foregroundStyle(.white)
                .padding(.horizontal, 14)
                .padding(.vertical, 11)
                .background(
                    LinearGradient(colors: [.orange, .pink],
                                   startPoint: .leading, endPoint: .trailing),
                    in: RoundedRectangle(cornerRadius: 12)
                )
            }
            .buttonStyle(.plain)

            HStack {
                Label(lang["settings.stats"], systemImage: "trophy.fill")
                    .font(.subheadline).bold()
                Spacer()
                Button(lang["settings.reset"]) { stats.reset() }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .buttonStyle(.plain)
            }

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                statCard(
                    value: formattedDistance,
                    label: lang["stats.walked"],
                    icon: "figure.walk",
                    color: .orange
                )
                statCard(
                    value: "\(stats.naps)",
                    label: stats.naps == 1 ? lang["stats.nap"] : lang["stats.naps"],
                    icon: "moon.fill",
                    color: .indigo
                )
                statCard(
                    value: "\(stats.scratches)",
                    label: stats.scratches == 1 ? lang["stats.scratch"] : lang["stats.scratches"],
                    icon: "hand.point.right.fill",
                    color: .pink
                )
                statCard(
                    value: "\(stats.daysTogether)j",
                    label: lang["stats.together"],
                    icon: "calendar.heart.fill",
                    color: .green
                )
            }
        }
    }

    private var formattedDistance: String {
        let m = stats.distanceMeters
        if m >= 1000 { return String(format: "%.1f km", m / 1000) }
        return String(format: "%.0f m", m)
    }

    private func statCard(value: String, label: String, icon: String, color: Color) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(color)
                .frame(width: 24)
            VStack(alignment: .leading, spacing: 1) {
                Text(value)
                    .font(.system(.callout, design: .rounded).weight(.bold))
                Text(label)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(10)
        .background(color.opacity(0.08), in: RoundedRectangle(cornerRadius: 10))
    }

    // MARK: – Updates section

    var updatesSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label(lang["settings.updates"], systemImage: "arrow.down.circle.fill")
                .font(.subheadline).bold()

            HStack(spacing: 10) {
                updateStatusView
                Spacer()
                Button(lang["settings.check_btn"]) {
                    Task { await updater.checkForUpdates() }
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .disabled(updater.state == .checking)
            }

            if case .available(let version, let url) = updater.state {
                HStack(spacing: 6) {
                    Image(systemName: "arrow.down.circle.fill").foregroundStyle(.green)
                    Text("v\(version) \(lang["update.available"])")
                        .fontWeight(.medium)
                    Spacer()
                    Link(lang["settings.download_btn"], destination: url)
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
            Text(lang["update.never"]).foregroundStyle(.secondary)
        case .checking:
            HStack(spacing: 6) { ProgressView().scaleEffect(0.7); Text(lang["update.checking"]) }
        case .upToDate:
            HStack(spacing: 6) {
                Image(systemName: "checkmark.circle.fill").foregroundStyle(.green)
                Text(lang["update.up_to_date"])
            }
        case .available(let v, _):
            HStack(spacing: 6) {
                Image(systemName: "exclamationmark.circle.fill").foregroundStyle(.orange)
                Text("v\(v) \(lang["update.available"])")
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
            Label(lang["settings.debug"], systemImage: "chart.bar.fill")
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
            languagePicker
            Spacer()
            Button(lang["settings.quit"]) { NSApplication.shared.terminate(nil) }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .tint(.red)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
    }

    private var languagePicker: some View {
        Picker("", selection: Binding(
            get: { lang.language },
            set: { lang.set($0) }
        )) {
            ForEach(Language.allCases) { l in
                Text("\(l.flag) \(l.displayName)").tag(l)
            }
        }
        .pickerStyle(.menu)
        .labelsHidden()
        .frame(width: 118)
        .controlSize(.small)
    }
}
