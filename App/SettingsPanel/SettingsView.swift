import SwiftUI
import AppKit
import ServiceManagement

// MARK: – Design tokens

private extension Color {
    static let nekoNavy   = Color(red: 0.055, green: 0.055, blue: 0.11)
    static let nekoCard   = Color.white.opacity(0.06)
    static let nekoBorder = Color.white.opacity(0.09)
    static let nekoMuted  = Color.white.opacity(0.45)
}

// MARK: – Section label

private struct SectionLabel: View {
    let text: String
    var body: some View {
        Text(text.uppercased())
            .font(.system(size: 10, weight: .semibold))
            .tracking(1.2)
            .foregroundStyle(Color.orange.opacity(0.75))
    }
}

// MARK: – Speed segmented control

private struct SpeedControl: View {
    @Binding var value: Float
    private let opts: [(String, Float)] = [("🐢", 0.4), ("🐱", 1.0), ("⚡", 2.5)]

    var body: some View {
        HStack(spacing: 2) {
            ForEach(opts, id: \.1) { emoji, v in
                Button {
                    withAnimation(.easeInOut(duration: 0.15)) { value = v }
                } label: {
                    Text(emoji)
                        .font(.system(size: 15))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 5)
                        .background(
                            RoundedRectangle(cornerRadius: 7)
                                .fill(abs(value - v) < 0.01
                                      ? Color.orange.opacity(0.25)
                                      : Color.clear)
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(3)
        .background(Color.nekoCard, in: RoundedRectangle(cornerRadius: 10))
        .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(Color.nekoBorder, lineWidth: 1))
    }
}

// MARK: – XP bar

private struct XPBar: View {
    let progress: Double

    var body: some View {
        GeometryReader { g in
            ZStack(alignment: .leading) {
                Capsule().fill(Color.white.opacity(0.08))
                Capsule()
                    .fill(LinearGradient(
                        colors: [.orange, Color(red: 1, green: 0.4, blue: 0.6)],
                        startPoint: .leading, endPoint: .trailing
                    ))
                    .frame(width: max(6, g.size.width * CGFloat(progress)))
                    .animation(.easeInOut(duration: 0.4), value: progress)
            }
        }
        .frame(height: 6)
    }
}

// MARK: – Stat card

private struct StatCard: View {
    let icon: String
    let value: String
    let label: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .firstTextBaseline, spacing: 5) {
                Text(icon)
                Text(value)
                    .font(.title3.bold())
                    .foregroundStyle(.white)
            }
            Text(label)
                .font(.caption)
                .foregroundStyle(Color.nekoMuted)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Color.nekoCard, in: RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(Color.nekoBorder, lineWidth: 1))
    }
}

// MARK: – Achievement pill

private struct AchievementPill: View {
    let achievement: Achievement
    let unlocked: Bool

    var body: some View {
        VStack(spacing: 4) {
            Text(achievement.icon)
                .font(.title3)
                .opacity(unlocked ? 1 : 0.22)
            Text(achievement.title)
                .font(.system(size: 8, weight: .medium))
                .foregroundStyle(unlocked ? Color.white.opacity(0.85) : Color.white.opacity(0.2))
                .lineLimit(2)
                .multilineTextAlignment(.center)
        }
        .frame(width: 58, height: 54)
        .background(
            unlocked ? Color.orange.opacity(0.12) : Color.white.opacity(0.035),
            in: RoundedRectangle(cornerRadius: 9)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 9)
                .strokeBorder(
                    unlocked ? Color.orange.opacity(0.28) : Color.white.opacity(0.05),
                    lineWidth: 1
                )
        )
    }
}

// MARK: – Skin preview

struct SkinPreview: View {
    let skinID: String
    let isSelected: Bool

    var body: some View {
        VStack(spacing: 4) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(isSelected ? Color.orange.opacity(0.18) : Color.white.opacity(0.06))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .strokeBorder(isSelected ? Color.orange : Color.white.opacity(0.1),
                                          lineWidth: isSelected ? 2 : 1)
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
                .foregroundStyle(isSelected ? .white : Color.nekoMuted)
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

    private var catStats: CatStats { renderer.catStats }

    var body: some View {
        VStack(spacing: 0) {
            headerBar
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 18) {
                    petSection
                    statsSection
                    achievementsSection
                    wrappedButton
                    personalizeSection
                    updatesSection
                }
                .padding(16)
            }
            bottomBar
        }
        .frame(width: 340)
        .background(Color.nekoNavy)
        .colorScheme(.dark)
    }

    // MARK: – Header

    private var headerBar: some View {
        HStack(spacing: 10) {
            Image(systemName: "pawprint.fill")
                .font(.title2)
                .foregroundStyle(.orange)
                .onTapGesture { handleEggTap() }
                .popover(isPresented: $showEgg, arrowEdge: .trailing) { eggPopover }

            VStack(alignment: .leading, spacing: 1) {
                TextField("Neko", text: $petName)
                    .textFieldStyle(.plain)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(.white)
                Text("v\(updater.currentVersion)")
                    .font(.caption2)
                    .foregroundStyle(Color.nekoMuted)
            }

            Spacer()

            HStack(spacing: 4) {
                Text("⭐")
                    .font(.caption)
                Text("Lv.\(catStats.level)")
                    .font(.caption.bold())
                    .foregroundStyle(.white)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color.orange.opacity(0.18), in: Capsule())
            .overlay(Capsule().strokeBorder(Color.orange.opacity(0.35), lineWidth: 1))

            Text(String(format: "%.0f fps", renderer.stats.fps))
                .font(.caption.monospacedDigit())
                .foregroundStyle(Color.nekoMuted)
                .padding(.horizontal, 7)
                .padding(.vertical, 4)
                .background(Color.white.opacity(0.07), in: Capsule())
        }
        .padding(.horizontal, 16)
        .padding(.top, 14)
        .padding(.bottom, 12)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(Color.white.opacity(0.08))
                .frame(height: 1)
        }
    }

    private func handleEggTap() {
        eggTaps += 1
        if eggTaps >= 5 { eggTaps = 0; showEgg = true }
    }

    private var eggPopover: some View {
        VStack(spacing: 10) {
            Image(systemName: "pawprint.fill").font(.title).foregroundStyle(.orange)
            Text("OnekoMac").font(.headline)
            Divider()
            Text("Made with ❤️ by").font(.subheadline).foregroundStyle(.secondary)
            Link("@hellov3an", destination: URL(string: "https://github.com/hellov3an")!)
                .font(.subheadline.weight(.semibold))
        }
        .padding(20)
        .frame(minWidth: 180)
    }

    // MARK: – Pet section (skin + size + speed)

    private var petSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionLabel(text: lang["settings.your_pet"])

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(renderer.allSkinIDs, id: \.self) { id in
                        SkinPreview(skinID: id, isSelected: renderer.currentSkinID == id)
                            .onTapGesture { renderer.setSkin(id) }
                            .animation(.easeInOut(duration: 0.15), value: renderer.currentSkinID)
                    }
                }
                .padding(.vertical, 2)
            }

            Button { onShowMarketplace() } label: {
                HStack(spacing: 6) {
                    Image(systemName: "square.grid.2x2.fill").font(.caption).foregroundStyle(.orange)
                    Text(lang["settings.marketplace"]).font(.caption.weight(.medium))
                }
                .padding(.horizontal, 12).padding(.vertical, 6)
                .background(Color.white.opacity(0.07), in: Capsule())
                .overlay(Capsule().strokeBorder(Color.white.opacity(0.1), lineWidth: 1))
            }
            .buttonStyle(.plain)

            HStack(spacing: 8) {
                Text("📐").font(.caption)
                Text(lang["settings.size"]).font(.callout).foregroundStyle(.white)
                Slider(
                    value: Binding(
                        get: { Double(renderer.catScale) },
                        set: { renderer.setCatScale(Float($0)) }
                    ),
                    in: 0.5...3.0, step: 0.25
                )
                Text(String(format: "%.2g×", renderer.catScale))
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(Color.nekoMuted)
                    .frame(width: 30, alignment: .trailing)
            }

            HStack(spacing: 8) {
                Text(lang["settings.speed"]).font(.callout).foregroundStyle(.white)
                Spacer()
                SpeedControl(value: Binding(
                    get: { renderer.speedMultiplier },
                    set: { renderer.setSpeedMultiplier($0) }
                ))
                .frame(width: 116)
            }
        }
    }

    // MARK: – Stats section

    private var statsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionLabel(text: lang["settings.stats"])

            HStack(spacing: 10) {
                StatCard(
                    icon: "🔥",
                    value: "\(catStats.streak)",
                    label: catStats.streak == 1 ? "day streak" : "day streak"
                )
                StatCard(
                    icon: "⭐",
                    value: "Lv.\(catStats.level)",
                    label: catStats.xpLabel
                )
            }

            VStack(spacing: 5) {
                XPBar(progress: catStats.xpProgress)
                HStack {
                    Text("\(Int(catStats.distanceMeters))m \(lang["stats.walked"])")
                        .font(.caption2)
                        .foregroundStyle(Color.nekoMuted)
                    Spacer()
                    Text(String(format: "%.0fm to Lv.%d", catStats.metersToNextLevel, catStats.level + 1))
                        .font(.caption2)
                        .foregroundStyle(Color.nekoMuted)
                }
            }
        }
    }

    // MARK: – Achievements section

    private var achievementsSection: some View {
        let manager = renderer.achievementManager
        let total   = allAchievements.count
        let count   = manager.unlockedIDs.count

        return VStack(alignment: .leading, spacing: 10) {
            HStack {
                SectionLabel(text: lang["settings.achievements"])
                Spacer()
                Text("\(count)/\(total)")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(count == total ? Color.orange : Color.nekoMuted)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(allAchievements) { a in
                        AchievementPill(
                            achievement: a,
                            unlocked: manager.unlockedIDs.contains(a.id)
                        )
                        .help(manager.unlockedIDs.contains(a.id)
                              ? "\(a.title) — \(a.description)"
                              : "???")
                    }
                }
                .padding(.vertical, 2)
            }
        }
    }

    // MARK: – Wrapped CTA

    private var wrappedButton: some View {
        Button { onShowWrapped() } label: {
            HStack(spacing: 10) {
                Image(systemName: "sparkles")
                Text(lang["wrapped.btn"])
                Spacer()
                Image(systemName: "chevron.right").font(.caption.weight(.semibold))
            }
            .font(.callout.weight(.semibold))
            .foregroundStyle(.white)
            .padding(.horizontal, 14).padding(.vertical, 11)
            .background(
                LinearGradient(colors: [.orange, Color(red: 1, green: 0.35, blue: 0.6)],
                               startPoint: .leading, endPoint: .trailing),
                in: RoundedRectangle(cornerRadius: 12)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: – Personalize section

    private var personalizeSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionLabel(text: "PERSONALIZE")

            Toggle(lang["settings.launch_login"], isOn: $launchAtLogin)
                .toggleStyle(.switch)
                .controlSize(.small)
                .font(.callout)
                .onChange(of: launchAtLogin) { newVal in
                    do {
                        if newVal { try SMAppService.mainApp.register() }
                        else      { try SMAppService.mainApp.unregister() }
                    } catch { launchAtLogin = !newVal }
                }

            Button { shareCardFromSettings() } label: {
                HStack(spacing: 6) {
                    Image(systemName: "square.and.arrow.up").font(.caption)
                    Text(lang["ob.card.share"]).font(.caption.weight(.medium))
                }
                .padding(.horizontal, 12).padding(.vertical, 6)
                .background(Color.white.opacity(0.07), in: Capsule())
                .overlay(Capsule().strokeBorder(Color.white.opacity(0.1), lineWidth: 1))
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

    // MARK: – Updates section

    private var updatesSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionLabel(text: lang["settings.updates"])

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
                    Text("v\(version) \(lang["update.available"])").fontWeight(.medium)
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
    private var updateStatusView: some View {
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

    // MARK: – Bottom bar

    private var bottomBar: some View {
        HStack {
            Link("GitHub", destination: URL(string: "https://github.com/hellov3an/OnekoMac")!)
                .font(.caption)
                .foregroundStyle(Color.nekoMuted)
            Spacer()
            languagePicker
            Spacer()
            Button(lang["settings.quit"]) { NSApplication.shared.terminate(nil) }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .tint(.red)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .overlay(alignment: .top) {
            Rectangle()
                .fill(Color.white.opacity(0.08))
                .frame(height: 1)
        }
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
