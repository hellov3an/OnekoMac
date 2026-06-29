import simd
import CoreGraphics

typealias Vec2 = SIMD2<Float>

extension Vec2 {
    var length: Float { simd_length(self) }
    var normalized: Vec2 { length > 0 ? self / length : .zero }

    init(_ point: CGPoint) {
        self.init(Float(point.x), Float(point.y))
    }
}

extension CGPoint {
    init(_ v: Vec2) {
        self.init(x: CGFloat(v.x), y: CGFloat(v.y))
    }
}

@inline(__always)
func lerp(_ a: Float, _ b: Float, _ t: Float) -> Float {
    a + (b - a) * t
}

@inline(__always)
func lerp(_ a: Vec2, _ b: Vec2, _ t: Float) -> Vec2 {
    a + (b - a) * t
}

@inline(__always)
func clamp(_ v: Float, _ lo: Float, _ hi: Float) -> Float {
    min(max(v, lo), hi)
}
