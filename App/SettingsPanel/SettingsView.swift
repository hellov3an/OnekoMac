import SwiftUI
import AppKit
import ServiceManagement

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
        guard let url  = SkinManager.gifURL(for: id),
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
    @EnvironmentObject var lang: LanguageManager
    let onShowWrapped: () -> Void
    let onShowMarketplace: () -> Void

    @AppStorage("pet_name") private var petName: String = "Neko"

    @State private var eggTaps = 0
    @State private var showEgg = false
    @State private var launchAtLogin: Bool = (SMAppService.mainApp.status == .enabled)

    var body: some View {
        VStack(spacing: 0) {
            titleBar
            Divider()
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    skinSection
                    Divider()
                    wrappedButton
                    Divider()
                    personalizeSection
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
                .onTapGesture { handleEggTap() }
                .popover(isPresented: $showEgg, arrowEdge: .trailing) {
                    eggPopover
                }

            VStack(alignment: .leading, spacing: 1) {
                TextField("Neko", text: $petName)
                    .textFieldStyle(.plain)
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

    // MARK: – Easter egg

    private func handleEggTap() {
        eggTaps += 1
        if eggTaps >= 5 {
            eggTaps = 0
            showEgg = true
        }
    }

    private var eggPopover: some View {
        VStack(spacing: 10) {
            Image(systemName: "pawprint.fill")
                .font(.title)
                .foregroundStyle(.orange)
            Text("OnekoMac")
                .font(.headline)
            Divider()
            Text("Made with ❤️ by")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Link("@hellov3an", destination: URL(string: "https://github.com/hellov3an")!)
                .font(.subheadline.weight(.semibold))
        }
        .padding(20)
        .frame(minWidth: 180)
    }

    // MARK: – Skin section

    var skinSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label(lang["settings.skin"], systemImage: "paintbrush.fill")
                .font(.subheadline).bold()

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(renderer.allSkinIDs, id: \.self) { id in
                        SkinPreview(skinID: id, isSelected: renderer.currentSkinID == id)
                            .onTapGesture { renderer.setSkin(id) }
                            .animation(.easeInOut(duration: 0.15), value: renderer.currentSkinID)
                    }
                }
            }

            Button {
                onShowMarketplace()
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "square.grid.2x2.fill")
                        .font(.caption)
                        .foregroundStyle(.orange)
                    Text(lang["settings.marketplace"])
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.primary)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(.quaternary, in: Capsule())
            }
            .buttonStyle(.plain)

            HStack {
                ColorPicker(lang["settings.tint"], selection: Binding(
                    get: { Color(renderer.tintColor) },
                    set: { renderer.setTintColor(NSColor($0)) }
                ))
                .font(.caption)
                Spacer()
                Button(lang["settings.tint_reset"]) { renderer.setTintColor(.white) }
                    .buttonStyle(.bordered)
                    .controlSize(.mini)
            }
        }
    }

    // MARK: – Personalize section (launch at login + share card)

    var personalizeSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Toggle(lang["settings.launch_login"], isOn: $launchAtLogin)
                .toggleStyle(.switch)
                .controlSize(.small)
                .font(.subheadline)
                .onChange(of: launchAtLogin) { newVal in
                    do {
                        if newVal { try SMAppService.mainApp.register() }
                        else      { try SMAppService.mainApp.unregister() }
                    } catch { launchAtLogin = !newVal }
                }

            Button { shareCardFromSettings() } label: {
                HStack(spacing: 6) {
                    Image(systemName: "square.and.arrow.up").font(.caption)
                    Text(lang["ob.card.share"]).font(.caption.weight(.medium)).foregroundStyle(.primary)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(.quaternary, in: Capsule())
            }
            .buttonStyle(.plain)
        }
    }

    private func shareCardFromSettings() {
        let name = petName.trimmingCharacters(in: .whitespaces).isEmpty ? "Neko" : petName
        let skinID = renderer.currentSkinID
        let dateStr: String = {
            if let stored = UserDefaults.standard.string(forKey: "adoption_date"),
               let date = ISO8601DateFormatter().date(from: stored) {
                let fmt = DateFormatter()
                fmt.dateStyle = .medium
                fmt.locale = Locale(identifier: lang.language.rawValue)
                return fmt.string(from: date)
            }
            let fmt = DateFormatter(); fmt.dateStyle = .medium
            return fmt.string(from: Date())
        }()
        let exportView = CardExportView(
            name: name, skinID: skinID, dateStr: dateStr,
            personality: lang["personality.\(skinID)"],
            adoptedLabel: lang["ob.card.adopted"],
            personalityLabel: lang["ob.card.personality"]
        )
        guard let image = renderCard(exportView: exportView) else { return }
        showSharePicker(for: image)
    }

    // MARK: – Wrapped CTA

    var wrappedButton: some View {
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
                .disabled({
                    switch updater.state {
                    case .checking, .downloading, .installing: return true
                    default: return false
                    }
                }())
            }

            if case .available(let version, let url) = updater.state {
                HStack(spacing: 6) {
                    Image(systemName: "arrow.down.circle.fill").foregroundStyle(.green)
                    Text("v\(version) \(lang["update.available"])")
                        .fontWeight(.medium)
                    Spacer()
                    Button(lang["update.install_btn"]) {
                        Task { await updater.downloadAndInstall(zipURL: url) }
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.green)
                    .controlSize(.small)
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
        case .downloading:
            HStack(spacing: 6) { ProgressView().scaleEffect(0.7); Text(lang["update.downloading"]) }
        case .installing:
            HStack(spacing: 6) { ProgressView().scaleEffect(0.7); Text(lang["update.installing"]) }
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
