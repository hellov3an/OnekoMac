import Foundation

// Sprite grid positions ported 1:1 from oneko.js spriteSets.
// Each tuple is (col, row) in the 8×4 atlas (256×128 px, 32×32 cells, top-left origin).
// JS uses negative offsets: [-3,-3] → col=3, row=3.
enum Anim: String {
    case idle, alert, tired, sleeping
    case scratchSelf, scratchWallN, scratchWallS, scratchWallE, scratchWallW
    case N, NE, E, SE, S, SW, W, NW
}

let spriteSets: [Anim: [(Int, Int)]] = [
    .idle:         [(3, 3)],
    .alert:        [(7, 3)],
    .scratchSelf:  [(5, 0), (6, 0), (7, 0)],
    .scratchWallN: [(0, 0), (0, 1)],
    .scratchWallS: [(7, 1), (6, 2)],
    .scratchWallE: [(2, 2), (2, 3)],
    .scratchWallW: [(4, 0), (4, 1)],
    .tired:        [(3, 2)],
    .sleeping:     [(2, 0), (2, 1)],
    .N:            [(1, 2), (1, 3)],
    .NE:           [(0, 2), (0, 3)],
    .E:            [(3, 0), (3, 1)],
    .SE:           [(5, 1), (5, 2)],
    .S:            [(6, 3), (7, 2)],
    .SW:           [(5, 3), (6, 1)],
    .W:            [(4, 2), (4, 3)],
    .NW:           [(1, 0), (1, 1)],
]

/// Returns the UV rect [u, v, width, height] in 0..1 atlas space for the given sprite+frame.
/// Atlas is 256×128 px → 8 columns × 4 rows of 32×32 px cells.
func spriteUV(_ anim: Anim, frame: Int) -> SIMD4<Float> {
    let frames = spriteSets[anim] ?? [(3, 3)]
    let (col, row) = frames[frame % frames.count]
    return SIMD4<Float>(Float(col) / 8, Float(row) / 4, 1.0 / 8, 1.0 / 4)
}

/// Oneko simulation — direct port of oneko.js `frame()` logic.
/// Coordinates: screen points, TOP-LEFT origin (matching CGEventTap).
final class NekoCat {
    // Current rendered state (read by render thread after logic tick).
    private(set) var posX: Float = 100
    private(set) var posY: Float = 100
    private(set) var currentUV = spriteUV(.idle, frame: 0)

    // Logic state (written only from simulation, which runs on CVLink thread).
    private var frameCount = 0
    private var idleTime = 0
    private var idleAnimation: Anim? = nil
    private var idleAnimFrame = 0
    private var logicAccum: Float = 0

    var screenWidth: Float  = 1440
    var screenHeight: Float = 900

    // The JS runs at 100ms ticks; we accumulate real dt to match.
    private let tickInterval: Float = 0.1

    // Speed in points per 100ms tick — matches JS nekoSpeed = 10.
    private let nekoSpeed: Float = 10

    func update(dt: Float, mouseX: Float, mouseY: Float) {
        logicAccum += dt
        if logicAccum >= tickInterval {
            logicAccum -= tickInterval
            // Target is the cursor; place cat slightly below cursor tip (+20 pts Y).
            logicTick(mouseX: mouseX, mouseY: mouseY + 20)
        }
    }

    // MARK: – JS frame() port

    private func logicTick(mouseX: Float, mouseY: Float) {
        frameCount += 1

        let diffX = posX - mouseX
        let diffY = posY - mouseY
        let distance = (diffX * diffX + diffY * diffY).squareRoot()

        if distance < nekoSpeed || distance < 48 {
            idleLogic()
            return
        }

        idleAnimation  = nil
        idleAnimFrame  = 0

        if idleTime > 1 {
            currentUV = spriteUV(.alert, frame: 0)
            idleTime = min(idleTime, 7) - 1
            return
        }

        // 8-directional movement (mirrors JS direction string building).
        var dir = ""
        if diffY / distance >  0.5 { dir += "N" }
        if diffY / distance < -0.5 { dir += "S" }
        if diffX / distance >  0.5 { dir += "W" }
        if diffX / distance < -0.5 { dir += "E" }

        let anim = Anim(rawValue: dir.isEmpty ? "idle" : dir) ?? .idle
        currentUV = spriteUV(anim, frame: frameCount)

        posX -= (diffX / distance) * nekoSpeed
        posY -= (diffY / distance) * nekoSpeed
        posX = min(max(32, posX), screenWidth  - 32)
        posY = min(max(32, posY), screenHeight - 32)
    }

    // MARK: – JS idle() port

    private func idleLogic() {
        idleTime += 1

        if idleTime > 10, idleAnimation == nil, Int.random(in: 0..<200) == 0 {
            var pool: [Anim] = [.sleeping, .scratchSelf]
            if posX < 32              { pool.append(.scratchWallW) }
            if posY < 32              { pool.append(.scratchWallN) }
            if posX > screenWidth  - 32 { pool.append(.scratchWallE) }
            if posY > screenHeight - 32 { pool.append(.scratchWallS) }
            idleAnimation = pool.randomElement()
        }

        switch idleAnimation {
        case .sleeping:
            if idleAnimFrame < 8 {
                currentUV = spriteUV(.tired, frame: 0)
            } else {
                currentUV = spriteUV(.sleeping, frame: idleAnimFrame / 4)
            }
            if idleAnimFrame > 192 { resetIdle() }

        case .scratchSelf, .scratchWallN, .scratchWallS, .scratchWallE, .scratchWallW:
            currentUV = spriteUV(idleAnimation!, frame: idleAnimFrame)
            if idleAnimFrame > 9 { resetIdle() }

        default:
            currentUV = spriteUV(.idle, frame: 0)
            return
        }
        idleAnimFrame += 1
    }

    private func resetIdle() {
        idleAnimation = nil
        idleAnimFrame = 0
    }
}
