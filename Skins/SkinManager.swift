import Foundation
import Metal
import MetalKit
import AppKit

final class SkinManager {
    private var textures: [String: MTLTexture] = [:]
    private let lock = NSLock()
    private var device: MTLDevice?

    static let skinIDs = ["classic", "dog", "tora", "maia", "vaporwave"]

    // MARK: – Custom sprites directory (Application Support)

    static var customSpritesDir: URL {
        FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
            .appendingPathComponent("OnekoMac/Sprites")
    }

    /// Returns the URL for a skin's GIF — custom (App Support) takes priority over bundle.
    static func gifURL(for id: String) -> URL? {
        let custom = customSpritesDir.appendingPathComponent("oneko-\(id).gif")
        if FileManager.default.fileExists(atPath: custom.path) { return custom }
        return Bundle.main.url(forResource: "oneko-\(id)", withExtension: "gif", subdirectory: "Sprites")
    }

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
            guard let url = SkinManager.gifURL(for: id) else { continue }
            loadSkinFromURL(id: id, url: url) {
                if !calledBack {
                    calledBack = true
                    DispatchQueue.main.async { completion() }
                }
            }
        }
    }

    /// Load any .gif files found in the custom sprites directory.
    func loadCustomSprites() {
        let dir = SkinManager.customSpritesDir
        guard let urls = try? FileManager.default.contentsOfDirectory(at: dir,
                                                                       includingPropertiesForKeys: nil)
        else { return }
        let gifURLs = urls.filter {
            $0.pathExtension == "gif" && $0.lastPathComponent.hasPrefix("oneko-")
        }
        for url in gifURLs {
            let id = String(url.deletingPathExtension().lastPathComponent.dropFirst("oneko-".count))
            guard !SkinManager.skinIDs.contains(id) else { continue }
            loadSkinFromURL(id: id, url: url) {}
        }
    }

    /// Download a skin GIF from `url`, save to App Support, then load it.
    func downloadSprite(id: String, from url: URL, completion: @escaping (Bool) -> Void) {
        URLSession.shared.dataTask(with: url) { [weak self] data, _, error in
            guard let self, let data, error == nil else {
                DispatchQueue.main.async { completion(false) }
                return
            }
            let dir = SkinManager.customSpritesDir
            do {
                try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
                let dest = dir.appendingPathComponent("oneko-\(id).gif")
                try data.write(to: dest)
                self.loadSkinFromURL(id: id, url: dest) {
                    DispatchQueue.main.async { completion(true) }
                }
            } catch {
                DispatchQueue.main.async { completion(false) }
            }
        }.resume()
    }

    // MARK: – Internal loader

    func loadSkinFromURL(id: String, url: URL, completion: @escaping () -> Void) {
        guard let dev = device else { return }
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

    // MARK: – Private

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
