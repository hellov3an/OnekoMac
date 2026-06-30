import SwiftUI
import AppKit

// MARK: – Onboarding host (5-step sliding wizard)

struct OnboardingView: View {
    @EnvironmentObject var lang: LanguageManager
    let renderer: MetalRenderer
    let onFinish: () -> Void

    @AppStorage("pet_name") private var petName: String = ""
    @State private var step = 0
    @State private var selectedSkin: String
    @State private var catPulse = false

    private let windowW: CGFloat = 520
    private let stepCount = 5

    init(renderer: MetalRenderer, onFinish: @escaping () -> Void) {
        self.renderer = renderer
        self.onFinish = onFinish
        self._selectedSkin = State(initialValue: renderer.currentSkinID)
    }

    var body: some View {
        ZStack {
            Color(red: 0.055, green: 0.055, blue: 0.11).ignoresSafeArea()

            VStack(spacing: 0) {
                stepsContainer
                navBar
            }
        }
        .frame(width: windowW, height: 480)
        .onChange(of: step, perform: { newStep in
            // Auto-fill name with skin choice if left blank when reaching welcome
            if newStep == 4 && petName.trimmingCharacters(in: .whitespaces).isEmpty {
                petName = selectedSkin.capitalized
            }
        })
    }

    // MARK: – Step container (offset-based horizontal slide)

    private var stepsContainer: some View {
        ZStack {
            conceptStep .offset(x: CGFloat(0 - step) * windowW)
            languageStep.offset(x: CGFloat(1 - step) * windowW)
            catStep     .offset(x: CGFloat(2 - step) * windowW)
            nameStep    .offset(x: CGFloat(3 - step) * windowW)
            welcomeStep .offset(x: CGFloat(4 - step) * windowW)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .clipped()
    }

    // MARK: – Step 0 · Concept

    private var conceptStep: some View {
        VStack(spacing: 0) {
            Spacer()

            Group {
                if let img = loadSprite(skinID: "classic", size: 88) {
                    Image(nsImage: img)
                        .interpolation(.none)
                        .frame(width: 88, height: 88)
                        .scaleEffect(catPulse ? 1.06 : 1.0)
                        .animation(.easeInOut(duration: 1.8).repeatForever(autoreverses: true),
                                   value: catPulse)
                        .onAppear { catPulse = true }
                }
            }
            .frame(height: 100)

            Spacer().frame(height: 4)

            Text(lang["ob.concept.eyebrow"].uppercased())
                .font(.caption)
                .tracking(2)
                .foregroundStyle(.white.opacity(0.35))

            Spacer().frame(height: 10)

            Text(lang["ob.concept.title"])
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .multilineTextAlignment(.center)
                .foregroundStyle(.white)

            Spacer().frame(height: 28)

            VStack(alignment: .leading, spacing: 14) {
                featureRow(icon: "cursorarrow.motionlines",      text: lang["ob.concept.f1"])
                featureRow(icon: "moon.zzz.fill",               text: lang["ob.concept.f2"])
                featureRow(icon: "rectangle.on.rectangle.fill", text: lang["ob.concept.f3"])
            }
            .frame(maxWidth: 300)

            Spacer()
        }
        .frame(width: windowW)
    }

    private func featureRow(icon: String, text: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(.orange)
                .frame(width: 22)
            Text(text)
                .foregroundStyle(.white.opacity(0.7))
                .font(.callout)
            Spacer()
        }
    }

    // MARK: – Step 1 · Language

    private var languageStep: some View {
        VStack(spacing: 0) {
            Spacer()

            Text(lang["ob.lang.title"])
                .font(.system(size: 26, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)

            Spacer().frame(height: 32)

            VStack(spacing: 12) {
                HStack(spacing: 12) {
                    ForEach(Array(Language.allCases.prefix(3))) { l in langTile(l) }
                }
                HStack(spacing: 12) {
                    ForEach(Array(Language.allCases.dropFirst(3))) { l in langTile(l) }
                }
            }

            Spacer()
        }
        .frame(width: windowW)
    }

    private func langTile(_ l: Language) -> some View {
        let isSelected = lang.language == l
        return Button {
            withAnimation(.easeInOut(duration: 0.15)) { lang.set(l) }
        } label: {
            VStack(spacing: 7) {
                Text(l.flag).font(.system(size: 34))
                Text(l.displayName)
                    .font(.callout)
                    .foregroundStyle(isSelected ? .white : .white.opacity(0.6))
            }
            .frame(width: 148, height: 82)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(isSelected ? Color.orange.opacity(0.18) : Color.white.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .strokeBorder(
                                isSelected ? Color.orange : Color.white.opacity(0.1),
                                lineWidth: isSelected ? 2 : 1
                            )
                    )
            )
        }
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.15), value: lang.language)
    }

    // MARK: – Step 2 · Cat

    private var catStep: some View {
        VStack(spacing: 0) {
            Spacer()

            Text(lang["ob.cat.title"])
                .font(.system(size: 26, weight: .bold, design: .rounded))
                .foregroundStyle(.white)

            Spacer().frame(height: 20)

            ZStack {
                Circle()
                    .fill(Color.orange.opacity(0.1))
                    .frame(width: 104, height: 104)

                if let img = loadSprite(skinID: selectedSkin, size: 72) {
                    Image(nsImage: img)
                        .interpolation(.none)
                        .frame(width: 72, height: 72)
                        .id(selectedSkin)
                        .transition(.scale(scale: 0.8).combined(with: .opacity))
                }
            }

            Spacer().frame(height: 20)

            HStack(spacing: 10) {
                ForEach(SkinManager.skinIDs, id: \.self) { id in catTile(id) }
            }

            Spacer().frame(height: 14)

            Text(lang["ob.cat.subtitle"])
                .font(.caption)
                .foregroundStyle(.white.opacity(0.35))

            Spacer()
        }
        .frame(width: windowW)
    }

    private func catTile(_ id: String) -> some View {
        let isSelected = selectedSkin == id
        return Button {
            withAnimation(.spring(response: 0.28, dampingFraction: 0.68)) {
                selectedSkin = id
            }
            renderer.setSkin(id)
        } label: {
            VStack(spacing: 5) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(isSelected ? Color.orange.opacity(0.18) : Color.white.opacity(0.05))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .strokeBorder(
                                    isSelected ? Color.orange : Color.white.opacity(0.1),
                                    lineWidth: isSelected ? 2 : 1
                                )
                        )
                        .frame(width: 68, height: 68)

                    if let img = loadSprite(skinID: id, size: 52) {
                        Image(nsImage: img)
                            .interpolation(.none)
                            .frame(width: 52, height: 52)
                    }
                }
                Text(id.capitalized)
                    .font(.caption2)
                    .foregroundStyle(isSelected ? .white : .white.opacity(0.45))
            }
        }
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.15), value: selectedSkin)
    }

    // MARK: – Step 3 · Name

    private var nameStep: some View {
        VStack(spacing: 0) {
            Spacer()

            ZStack {
                Circle()
                    .fill(Color.orange.opacity(0.1))
                    .frame(width: 104, height: 104)

                if let img = loadSprite(skinID: selectedSkin, size: 72) {
                    Image(nsImage: img)
                        .interpolation(.none)
                        .frame(width: 72, height: 72)
                        .id(selectedSkin)
                }
            }

            Spacer().frame(height: 26)

            Text(lang["ob.name.title"])
                .font(.system(size: 26, weight: .bold, design: .rounded))
                .foregroundStyle(.white)

            Spacer().frame(height: 22)

            TextField(selectedSkin.capitalized, text: $petName)
                .textFieldStyle(.plain)
                .font(.system(size: 30, weight: .bold, design: .rounded))
                .multilineTextAlignment(.center)
                .foregroundStyle(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 14)
                .background(Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 16))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .strokeBorder(.white.opacity(0.15), lineWidth: 1)
                )
                .frame(maxWidth: 280)

            Spacer().frame(height: 14)

            Text(lang["ob.name.subtitle"])
                .font(.caption)
                .foregroundStyle(.white.opacity(0.35))

            Spacer()
        }
        .frame(width: windowW)
    }

    // MARK: – Step 4 · ID Card

    private var welcomeStep: some View {
        VStack(spacing: 0) {
            Spacer()

            Text(lang["ob.card.eyebrow"])
                .font(.system(.caption2, design: .rounded).weight(.heavy))
                .tracking(2)
                .foregroundStyle(.orange)

            Spacer().frame(height: 16)

            // Card
            VStack(spacing: 0) {
                // Cat sprite
                ZStack {
                    Circle().fill(Color.orange.opacity(0.12)).frame(width: 96, height: 96)
                    Circle().fill(Color.orange.opacity(0.06)).frame(width: 116, height: 116)
                    if let img = loadSprite(skinID: selectedSkin, size: 72) {
                        Image(nsImage: img)
                            .interpolation(.none)
                            .frame(width: 72, height: 72)
                    }
                }
                .padding(.top, 24)

                Spacer().frame(height: 14)

                Text(displayName)
                    .font(.system(size: 26, weight: .black, design: .rounded))
                    .foregroundStyle(.white)

                Spacer().frame(height: 16)

                Divider().background(.white.opacity(0.15))

                Spacer().frame(height: 16)

                // Info rows
                VStack(spacing: 10) {
                    cardRow(icon: "calendar", label: lang["ob.card.adopted"],
                            value: adoptionDateDisplay)
                    cardRow(icon: "paintbrush.fill", label: "Skin",
                            value: selectedSkin.capitalized)
                    cardRow(icon: "sparkles", label: lang["ob.card.personality"],
                            value: lang["personality.\(selectedSkin)"])
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
            }
            .frame(width: 300)
            .background(.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 20))
            .overlay(RoundedRectangle(cornerRadius: 20).strokeBorder(.white.opacity(0.12), lineWidth: 1))

            Spacer()
        }
        .frame(width: windowW)
    }

    private func cardRow(icon: String, label: String, value: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(.orange)
                .frame(width: 16)
            Text(label)
                .font(.caption)
                .foregroundStyle(.white.opacity(0.45))
            Spacer()
            Text(value)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.white)
        }
    }

    private var displayName: String {
        petName.trimmingCharacters(in: .whitespaces).isEmpty
            ? selectedSkin.capitalized
            : petName.trimmingCharacters(in: .whitespaces)
    }

    private var adoptionDateDisplay: String {
        let fmt = DateFormatter()
        fmt.dateStyle = .medium
        fmt.timeStyle = .none
        fmt.locale = Locale(identifier: lang.language.rawValue)
        return fmt.string(from: Date())
    }

    // MARK: – Navigation bar

    private var navBar: some View {
        HStack(spacing: 0) {
            Group {
                if step > 0 {
                    Button(lang["btn.back"]) {
                        withAnimation(.spring(response: 0.38, dampingFraction: 0.85)) {
                            step -= 1
                        }
                    }
                    .font(.callout)
                    .foregroundStyle(.white.opacity(0.45))
                    .buttonStyle(.plain)
                }
            }
            .frame(width: 80, alignment: .leading)

            Spacer()

            HStack(spacing: 6) {
                ForEach(0..<stepCount, id: \.self) { i in
                    Capsule()
                        .fill(i == step ? Color.orange : Color.white.opacity(0.2))
                        .frame(width: i == step ? 22 : 6, height: 6)
                        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: step)
                }
            }

            Spacer()

            Group {
                if step < stepCount - 1 {
                    Button {
                        withAnimation(.spring(response: 0.38, dampingFraction: 0.85)) {
                            step += 1
                        }
                    } label: {
                        nextLabel(lang["btn.next"])
                    }
                    .buttonStyle(.plain)
                } else {
                    Button { onFinish() } label: {
                        nextLabel(lang["btn.start"])
                    }
                    .buttonStyle(.plain)
                }
            }
            .frame(width: 110, alignment: .trailing)
        }
        .padding(.horizontal, 28)
        .padding(.vertical, 18)
    }

    private func nextLabel(_ text: String) -> some View {
        Text(text)
            .font(.callout.weight(.semibold))
            .foregroundStyle(.white)
            .padding(.horizontal, 18)
            .padding(.vertical, 7)
            .background(Color.orange, in: Capsule())
    }

    // MARK: – Helpers

    private func loadSprite(skinID: String, size: CGFloat) -> NSImage? {
        guard let url  = SkinManager.gifURL(for: skinID),
              let data = try? Data(contentsOf: url),
              let src  = CGImageSourceCreateWithData(data as CFData, nil),
              let full = CGImageSourceCreateImageAtIndex(src, 0, nil) else { return nil }

        let rect = CGRect(x: 3 * 32, y: 3 * 32, width: 32, height: 32)
        guard let cropped = full.cropping(to: rect) else { return nil }
        let img = NSImage(cgImage: cropped, size: NSSize(width: size, height: size))
        img.cacheMode = .never
        return img
    }
}
