import Metal
import MetalKit
import QuartzCore
import AppKit
import Combine

struct Uniforms {
    var screenSize: SIMD2<Float>
}

// Must mirror Shader.metal SpriteInstance exactly.
struct SpriteInstanceGPU {
    var position: SIMD2<Float>
    var size:     SIMD2<Float>
    var uvRect:   SIMD4<Float>
}

struct DebugStats {
    var fps: Double    = 0
    var gpuMs: Double  = 0
    var petCount: Int  = 1
}

final class MetalRenderer: ObservableObject {
    let view: NSView          // drop into OverlayWindow

    private let device: MTLDevice
    private let metalLayer: CAMetalLayer
    private let commandQueue: MTLCommandQueue
    private var pipeline: MTLRenderPipelineState!
    private var sampler: MTLSamplerState!
    // Triple-buffered per-instance buffer (single sprite).
    private var instanceBuffers: [MTLBuffer] = []
    private var bufferIndex = 0

    private let displayLink = CVDisplayLinkManager()
    private let mouseTracker = MouseTracker()
    let neko = NekoCat()
    let skinManager = SkinManager()
    let catStats = CatStats()

    private let frameSemaphore = DispatchSemaphore(value: 3)
    private var fpsAccum: Double = 0
    private var fpsFrames = 0
    private var pendingStats = DebugStats()

    @Published private(set) var stats = DebugStats()
    @Published private(set) var currentSkinID = "classic"
    @Published private(set) var allSkinIDs: [String] = SkinManager.skinIDs
    @Published private(set) var tintColor: NSColor = .white
    private(set) var tintRGBA: SIMD4<Float> = SIMD4<Float>(1, 1, 1, 1)

    init() throws {
        guard let dev = MTLCreateSystemDefaultDevice() else {
            throw NSError(domain: "OnekoMac", code: 0,
                          userInfo: [NSLocalizedDescriptionKey: "No Metal device"])
        }
        device = dev

        guard let queue = dev.makeCommandQueue() else {
            throw NSError(domain: "OnekoMac", code: 1,
                          userInfo: [NSLocalizedDescriptionKey: "No command queue"])
        }
        commandQueue = queue

        // CAMetalLayer
        metalLayer = CAMetalLayer()
        metalLayer.device = dev
        metalLayer.pixelFormat = .bgra8Unorm
        metalLayer.isOpaque = false
        metalLayer.framebufferOnly = true
        metalLayer.maximumDrawableCount = 3
        metalLayer.allowsNextDrawableTimeout = false
        if let screen = NSScreen.main {
            let s = screen.backingScaleFactor
            metalLayer.contentsScale = s
            metalLayer.drawableSize = CGSize(
                width:  screen.frame.width  * s,
                height: screen.frame.height * s)
        }

        let hostView = NSView()
        hostView.wantsLayer = true
        hostView.layer = metalLayer
        view = hostView

        // Triple-buffered instance buffers — just 1 sprite each.
        let stride = MemoryLayout<SpriteInstanceGPU>.stride
        for _ in 0..<3 {
            instanceBuffers.append(dev.makeBuffer(length: stride, options: .storageModeShared)!)
        }

        skinManager.setDevice(dev)

        // Wire stat callbacks.
        neko.onStep    = { [weak self] pts in self?.catStats.addDistance(pts) }
        neko.onNap     = { [weak self] in self?.catStats.recordNap() }
        neko.onScratch = { [weak self] in self?.catStats.recordScratch() }

        try buildPipeline()
        buildSampler()

        // Load bundled skins (async — falls back to placeholder until ready).
        skinManager.loadAll { [weak self] in
            self?.currentSkinID = "classic"
        }
        // Also load any previously downloaded custom skins.
        skinManager.loadCustomSprites()

        startLoop()

        if let hex = UserDefaults.standard.string(forKey: "tint_color"),
           let c = Self.color(fromHex: hex) {
            setTintColor(c)
        }
    }

    func setTintColor(_ color: NSColor) {
        tintColor = color
        let c = color.usingColorSpace(.sRGB) ?? color
        tintRGBA = SIMD4<Float>(Float(c.redComponent), Float(c.greenComponent),
                                Float(c.blueComponent), 1)
        UserDefaults.standard.set(
            String(format: "#%02X%02X%02X",
                   Int(c.redComponent * 255),
                   Int(c.greenComponent * 255),
                   Int(c.blueComponent * 255)),
            forKey: "tint_color")
    }

    private static func color(fromHex hex: String) -> NSColor? {
        let s = hex.trimmingCharacters(in: .init(charactersIn: "#"))
        guard s.count == 6, let rgb = UInt32(s, radix: 16) else { return nil }
        let r = CGFloat((rgb >> 16) & 0xFF) / 255
        let g = CGFloat((rgb >> 8)  & 0xFF) / 255
        let b = CGFloat( rgb        & 0xFF) / 255
        return NSColor(srgbRed: r, green: g, blue: b, alpha: 1)
    }

    // MARK: – Skin switching

    func setSkin(_ id: String) {
        currentSkinID = id
    }

    var availableSkins: [String] { skinManager.availableIDs }

    func refreshAvailableSkins() {
        let ids = skinManager.availableIDs
        DispatchQueue.main.async { self.allSkinIDs = ids }
    }

    // MARK: – Loop

    private func startLoop() {
        displayLink.start { [weak self] dt in self?.tick(dt: dt) }
    }

    private func tick(dt: Double) {
        // Use the union of all screens so the cat can cross between displays.
        let union = NSScreen.screens.reduce(NSRect.null) { $0.union($1.frame) }
        neko.screenWidth  = Float(union.width)
        neko.screenHeight = Float(union.height)
        let s = NSScreen.main?.backingScaleFactor ?? 1.0
        metalLayer.drawableSize = CGSize(width: union.width * s, height: union.height * s)

        let mouse = mouseTracker.position
        neko.update(dt: Float(dt), mouseX: mouse.x, mouseY: mouse.y)
        render(dt: dt)
    }

    // MARK: – Render

    private func render(dt: Double) {
        guard frameSemaphore.wait(timeout: .now()) == .success else { return }

        guard let drawable = metalLayer.nextDrawable() else { frameSemaphore.signal(); return }
        guard let cmdBuf   = commandQueue.makeCommandBuffer() else { frameSemaphore.signal(); return }
        cmdBuf.addCompletedHandler { [weak self] _ in self?.frameSemaphore.signal() }

        let union = NSScreen.screens.reduce(NSRect.null) { $0.union($1.frame) }
        let screenW = Float(union.width  > 0 ? union.width  : 1440)
        let screenH = Float(union.height > 0 ? union.height : 900)

        // Upload instance for the single cat.
        let buf = instanceBuffers[bufferIndex]
        bufferIndex = (bufferIndex + 1) % 3
        let ptr = buf.contents().bindMemory(to: SpriteInstanceGPU.self, capacity: 1)
        ptr[0] = SpriteInstanceGPU(
            position: SIMD2<Float>(neko.posX, neko.posY),
            size:     SIMD2<Float>(64, 64),  // 2x pixel art upscale (same as browser on Retina)
            uvRect:   neko.currentUV
        )

        let t0 = CACurrentMediaTime()

        let passDesc = MTLRenderPassDescriptor()
        passDesc.colorAttachments[0].texture     = drawable.texture
        passDesc.colorAttachments[0].loadAction  = .clear
        passDesc.colorAttachments[0].storeAction = .store
        passDesc.colorAttachments[0].clearColor  = MTLClearColor(red: 0, green: 0, blue: 0, alpha: 0)

        guard let enc = cmdBuf.makeRenderCommandEncoder(descriptor: passDesc) else {
            frameSemaphore.signal(); return
        }
        enc.setRenderPipelineState(pipeline)
        enc.setFragmentSamplerState(sampler, index: 0)

        var uni = Uniforms(screenSize: SIMD2<Float>(screenW, screenH))
        enc.setVertexBuffer(buf, offset: 0, index: 0)
        enc.setVertexBytes(&uni, length: MemoryLayout<Uniforms>.size, index: 1)

        if let tex = skinManager.texture(id: currentSkinID) {
            enc.setFragmentTexture(tex, index: 0)
            var tint = tintRGBA
            enc.setFragmentBytes(&tint, length: MemoryLayout<SIMD4<Float>>.size, index: 1)
            enc.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: 4)
        }

        enc.endEncoding()
        cmdBuf.present(drawable)
        cmdBuf.commit()

        accumStats(dt: dt, gpuMs: (CACurrentMediaTime() - t0) * 1000)
    }

    // MARK: – Pipeline

    private func buildPipeline() throws {
        let library: MTLLibrary
        if let lib = try? device.makeDefaultLibrary(bundle: .main),
           lib.functionNames.contains("sprite_vertex") {
            library = lib
        } else {
            library = try device.makeLibrary(source: RenderPipeline.inlineShaderSource, options: nil)
        }

        guard let vert = library.makeFunction(name: "sprite_vertex"),
              let frag = library.makeFunction(name: "sprite_fragment") else {
            throw NSError(domain: "OnekoMac", code: 2, userInfo: [NSLocalizedDescriptionKey: "Missing shader functions"])
        }

        let desc = MTLRenderPipelineDescriptor()
        desc.vertexFunction   = vert
        desc.fragmentFunction = frag
        desc.colorAttachments[0].pixelFormat = metalLayer.pixelFormat
        desc.colorAttachments[0].isBlendingEnabled = true
        desc.colorAttachments[0].sourceRGBBlendFactor        = .sourceAlpha
        desc.colorAttachments[0].destinationRGBBlendFactor   = .oneMinusSourceAlpha
        desc.colorAttachments[0].sourceAlphaBlendFactor      = .one
        desc.colorAttachments[0].destinationAlphaBlendFactor = .oneMinusSourceAlpha
        pipeline = try device.makeRenderPipelineState(descriptor: desc)
    }

    private func buildSampler() {
        let d = MTLSamplerDescriptor()
        d.minFilter = .nearest
        d.magFilter = .nearest
        sampler = device.makeSamplerState(descriptor: d)!
    }

    private func accumStats(dt: Double, gpuMs: Double) {
        fpsAccum  += dt
        fpsFrames += 1
        if fpsAccum >= 0.5 {
            pendingStats.fps   = Double(fpsFrames) / fpsAccum
            pendingStats.gpuMs = gpuMs
            fpsAccum  = 0
            fpsFrames = 0
            let snap = pendingStats
            DispatchQueue.main.async { [weak self] in self?.stats = snap }
        }
    }
}
