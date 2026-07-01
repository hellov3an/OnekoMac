import Foundation

/// Autonomous random laser-dot movement in simulation space (top-left origin, Y-down).
final class LaserMover {
    private(set) var x: Float = 200
    private(set) var y: Float = 200

    private var vx: Float = 0
    private var vy: Float = 0
    private var screenW: Float = 1440
    private var screenH: Float = 900
    private var flickTimer: Float = 0

    func place(x: Float, y: Float) {
        self.x = x
        self.y = y
        vx = 0; vy = 0
        flickTimer = 0
    }

    func setScreen(width: Float, height: Float) {
        screenW = width
        screenH = height
    }

    func tick(dt: Float) {
        flickTimer -= dt
        if flickTimer <= 0 {
            let angle = Float.random(in: 0 ..< .pi * 2)
            let speed = Float.random(in: 250 ... 650)
            vx = cos(angle) * speed
            vy = sin(angle) * speed
            flickTimer = Float.random(in: 0.25 ... 1.4)
        }

        // Small continuous jitter
        vx += Float.random(in: -300 ... 300) * dt
        vy += Float.random(in: -300 ... 300) * dt

        // Clamp speed
        let spd = sqrt(vx * vx + vy * vy)
        let maxSpd: Float = 720
        if spd > maxSpd { vx = vx / spd * maxSpd; vy = vy / spd * maxSpd }

        x += vx * dt
        y += vy * dt

        // Bounce off edges (top margin leaves room for menu bar)
        let mT: Float = 50; let mO: Float = 40
        if x < mO            { x = mO;            vx =  abs(vx) }
        if x > screenW - mO  { x = screenW - mO;  vx = -abs(vx) }
        if y < mT            { y = mT;             vy =  abs(vy) }
        if y > screenH - mO  { y = screenH - mO;  vy = -abs(vy) }
    }
}
