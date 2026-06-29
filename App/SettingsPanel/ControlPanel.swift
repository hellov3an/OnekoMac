import SwiftUI
import AppKit

struct ControlPanel: View {
    @ObservedObject var renderer: MetalRenderer
    @State private var showDebug = false

    var body: some View {
        VStack(spacing: 0) {
            headerView
            Divider()
            VStack(spacing: 0) {
                skinRow
                Divider().padding(.leading, 16)
                debugRow
                Divider().padding(.leading, 16)
                quitRow
            }
        }
        .frame(width: 280)
        .background(.ultraThinMaterial)
    }

    // MARK: – Header

    var headerView: some View {
        HStack(spacing: 10) {
            Image(systemName: "pawprint.fill")
                .font(.title3)
                .foregroundStyle(.orange)
            Text("OnekoMac+")
                .font(.headline)
            Spacer()
            Text(String(format: "%.0f fps", renderer.stats.fps))
                .font(.caption.monospacedDigit())
                .foregroundStyle(.secondary)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(Color.secondary.opacity(0.15), in: Capsule())
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    // MARK: – Skin row

    var skinRow: some View {
        HStack {
            Label("Skin", systemImage: "paintbrush.fill")
                .font(.callout)
                .foregroundStyle(.primary)
            Spacer()
            Picker("", selection: Binding(
                get: { renderer.currentSkinID },
                set: { renderer.setSkin($0) }
            )) {
                ForEach(SkinManager.skinIDs, id: \.self) { id in
                    Text(id.capitalized).tag(id)
                }
            }
            .labelsHidden()
            .frame(width: 120)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 11)
        .contentShape(Rectangle())
    }

    // MARK: – Debug row (expandable)

    var debugRow: some View {
        VStack(spacing: 0) {
            Button {
                withAnimation(.easeInOut(duration: 0.15)) { showDebug.toggle() }
            } label: {
                HStack {
                    Label("Debug info", systemImage: "chart.bar.fill")
                        .font(.callout)
                        .foregroundStyle(.primary)
                    Spacer()
                    Image(systemName: showDebug ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 11)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if showDebug {
                VStack(spacing: 6) {
                    statLine("FPS",        String(format: "%.1f", renderer.stats.fps))
                    statLine("GPU ms",     String(format: "%.2f", renderer.stats.gpuMs))
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 10)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }

    func statLine(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label).foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.system(.callout, design: .monospaced))
                .fontWeight(.medium)
        }
        .font(.callout)
    }

    // MARK: – Quit row

    var quitRow: some View {
        Button(role: .destructive) {
            NSApplication.shared.terminate(nil)
        } label: {
            Label("Quit OnekoMac", systemImage: "xmark.circle.fill")
                .font(.callout)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .buttonStyle(.plain)
        .foregroundStyle(.red)
        .padding(.horizontal, 16)
        .padding(.vertical, 11)
        .contentShape(Rectangle())
    }
}
