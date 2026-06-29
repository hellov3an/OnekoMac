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

    private let frameSemaphore = DispatchSemaphore(value: 3)
    private var fpsAccum: Double = 0
    private var fpsFrames = 0
    private var pendingStats = DebugStats()

    @Published private(set) var stats = DebugStats()
    @Published private(set) var currentSkinID = "classic"

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

        try buildPipeline()
        buildSampler()

        // Load skins (async — falls back to placeholder until ready).
        skinManager.loadAll { [weak self] in
            self?.currentSkinID = "classic"
        }

        startLoop()
    }

    // MARK: – Skin switching

    func setSkin(_ id: String) {
        guard skinManager.texture(id: id) != nil else { return }
        currentSkinID = id
    }

    var availableSkins: [String] { skinManager.availableIDs }

    // MARK: – Loop

    private func startLoop() {
        displayLink.start { [weak self] dt in self?.tick(dt: dt) }
    }

    private func tick(dt: Double) {
        // Update screen size from main screen (safe to read from any thread).
        if let screen = NSScreen.main {
            neko.screenWidth  = Float(screen.frame.width)
            neko.screenHeight = Float(screen.frame.height)
            let s = screen.backingScaleFactor
            metalLayer.drawableSize = CGSize(
                width:  screen.frame.width  * s,
                height: screen.frame.height * s)
        }

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

        let screen = NSScreen.main
        let screenW = Float(screen?.frame.width  ?? 1440)
        let screenH = Float(screen?.frame.height ?? 900)

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
