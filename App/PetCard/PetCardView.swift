import SwiftUI
import AppKit

// MARK: – Reusable pet ID card

struct PetCardView: View {
    let name: String
    let skinID: String
    let dateStr: String
    let personality: String
    let adoptedLabel: String
    let personalityLabel: String

    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                Circle().fill(Color.orange.opacity(0.12)).frame(width: 96, height: 96)
                Circle().fill(Color.orange.opacity(0.06)).frame(width: 116, height: 116)
                if let img = idleSprite(skinID: skinID, size: 72) {
                    Image(nsImage: img)
                        .interpolation(.none)
                        .frame(width: 72, height: 72)
                }
            }
            .padding(.top, 24)

            Spacer().frame(height: 14)

            Text(name)
                .font(.system(size: 26, weight: .black, design: .rounded))
                .foregroundStyle(.white)

            Spacer().frame(height: 16)

            Divider().background(.white.opacity(0.15))

            Spacer().frame(height: 16)

            VStack(spacing: 10) {
                cardRow(icon: "calendar",        label: adoptedLabel,      value: dateStr)
                cardRow(icon: "paintbrush.fill", label: "Skin",            value: skinID.capitalized)
                cardRow(icon: "sparkles",        label: personalityLabel,  value: personality)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
        }
        .frame(width: 300)
        .background(.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 20))
        .overlay(RoundedRectangle(cornerRadius: 20).strokeBorder(.white.opacity(0.12), lineWidth: 1))
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
}

// MARK: – Fixed-size dark wrapper used when rendering to image for sharing

struct CardExportView: View {
    let name: String
    let skinID: String
    let dateStr: String
    let personality: String
    let adoptedLabel: String
    let personalityLabel: String

    var body: some View {
        ZStack {
            Color(red: 0.055, green: 0.055, blue: 0.11)
            PetCardView(
                name: name, skinID: skinID, dateStr: dateStr,
                personality: personality,
                adoptedLabel: adoptedLabel, personalityLabel: personalityLabel
            )
        }
        .frame(width: 360, height: 420)
    }
}

// MARK: – Sprite helper (idle frame from atlas)

func idleSprite(skinID: String, size: CGFloat) -> NSImage? {
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

// MARK: – Render + share helpers

func renderCard(exportView: CardExportView) -> NSImage? {
    let host = NSHostingView(rootView: exportView)
    host.frame = NSRect(x: 0, y: 0, width: 360, height: 420)
    guard let rep = host.bitmapImageRepForCachingDisplay(in: host.bounds) else { return nil }
    host.cacheDisplay(in: host.bounds, to: rep)
    let image = NSImage(size: host.bounds.size)
    image.addRepresentation(rep)
    return image
}

func showSharePicker(for image: NSImage) {
    guard let view = NSApp.keyWindow?.contentView else { return }
    let picker = NSSharingServicePicker(items: [image])
    picker.show(relativeTo: .zero, of: view, preferredEdge: .minY)
}
