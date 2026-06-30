import Foundation
import Metal
import MetalKit
import AppKit

final class SkinManager {
    private var textures: [String: MTLTexture] = [:]
    private let lock = NSLock()
    private var device: MTLDevice?

    static let skinIDs = ["classic", "dog", "tora", "maia", "vaporwave"]

    var availableIDs: [String] {
        lock.lock(); defer { lock.unlock() }
        return Array(textures.keys).sorted()
    }

    func setDevice(_ dev: MTLDevice) { device = dev }

    func texture(id: String) -> MTLTexture? {
        lock.lock(); defer { lock.unlock() }
        return textures[id]
    }

    /// Load all bundled GIF skins. Calls `completion` on main thread when first skin is ready.
    func loadAll(completion: @escaping () -> Void) {
        var calledBack = false
        for id in SkinManager.skinIDs {
            loadSkin(id: id) {
                if !calledBack {
                    calledBack = true
                    DispatchQueue.main.async { completion() }
                }
            }
        }
    }

    // MARK: – Private

    private func loadSkin(id: String, completion: @escaping () -> Void) {
        guard let dev = device else { return }
        guard let url = Bundle.main.url(forResource: "oneko-\(id)", withExtension: "gif", subdirectory: "Sprites") else {
            Log.skin.error("GIF not found in bundle: oneko-\(id).gif (Sprites/)")
            return
        }

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self else { return }
            guard let tex = self.gifToTexture(url: url, device: dev) else {
                Log.skin.error("Failed to decode GIF for skin: \(id)")
                return
            }
            self.lock.lock()
            self.textures[id] = tex
            self.lock.unlock()
            Log.skin.info("Skin loaded: \(id)")
            completion()
        }
    }

    /// Decode GIF (static sprite sheet) → MTLTexture via Core Graphics.
    private func gifToTexture(url: URL, device: MTLDevice) -> MTLTexture? {
        guard let data = try? Data(contentsOf: url),
              let source = CGImageSourceCreateWithData(data as CFData, nil),
              let cgImage = CGImageSourceCreateImageAtIndex(source, 0, nil) else {
            return nil
        }

        let w = cgImage.width
        let h = cgImage.height

        let desc = MTLTextureDescriptor.texture2DDescriptor(
            pixelFormat: .rgba8Unorm, width: w, height: h, mipmapped: false)
        desc.usage = .shaderRead
        desc.storageMode = .shared
        guard let tex = device.makeTexture(descriptor: desc) else { return nil }

        // Draw CGImage into a raw RGBA buffer.
        var pixels = [UInt8](repeating: 0, count: w * h * 4)
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        guard let ctx = CGContext(
            data: &pixels,
            width: w, height: h,
            bitsPerComponent: 8,
            bytesPerRow: w * 4,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else { return nil }

        // Off-screen CGBitmapContext stores row 0 at the top — no flip needed.
        ctx.draw(cgImage, in: CGRect(x: 0, y: 0, width: w, height: h))

        tex.replace(
            region: MTLRegionMake2D(0, 0, w, h),
            mipmapLevel: 0,
            withBytes: pixels,
            bytesPerRow: w * 4
        )
        return tex
    }
}
