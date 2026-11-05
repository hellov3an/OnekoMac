import Foundation
import AppKit
import Darwin

public struct SwarmSlot {
    public var x: Float
    public var y: Float
    public var time: Double
}

/// SwarmCoordinator coordinates multiple concurrent OnekoMac instances via low-overhead
/// POSIX shared memory (/tmp/oneko_swarm.bin), preventing overlaps through Boids repulsion
/// and ensuring cats avoid the MacBook camera notch when sleeping on the menu bar.
public final class SwarmCoordinator {
    public static let shared = SwarmCoordinator()
    private let path = "/tmp/oneko_swarm.bin"
    public private(set) var myIndex: Int = 0
    private var offsetX: Float = 0
    private var offsetY: Float = 20

    public init() {
        let bundleId = Bundle.main.bundleIdentifier?.lowercased() ?? ""
        if bundleId.contains("sari") || bundleId.contains("ginger") {
            myIndex = 0
            offsetX = 56
            offsetY = 18
        } else if bundleId.contains("siyah") || bundleId.contains("midnight") {
            myIndex = 1
            offsetX = -56
            offsetY = 18
        } else if bundleId.contains("tekir") || bundleId.contains("tabby") {
            myIndex = 2
            offsetX = 0
            offsetY = 72
        } else {
            let idx = UserDefaults.standard.integer(forKey: "swarm_index")
            myIndex = idx
            if idx == 1 { offsetX = -56; offsetY = 18 }
            else if idx == 2 { offsetX = 0; offsetY = 72 }
            else { offsetX = 56; offsetY = 18 }
        }
    }

    public func targetOffset() -> (Float, Float) {
        (offsetX, offsetY)
    }

    /// Dynamically calculates a safe resting X position on the menu bar,
    /// avoiding the physical MacBook camera notch with safety buffers.
    public func randomSleepingX(screenWidth: Float) -> Float {
        var notchLeft: Float = screenWidth * 0.44
        var notchRight: Float = screenWidth * 0.56
        
        if let screen = NSScreen.main,
           let tl = screen.auxiliaryTopLeftArea,
           let tr = screen.auxiliaryTopRightArea {
            notchLeft = Float(tl.maxX)
            notchRight = Float(tr.minX)
        }
        
        // 45pt safety margins around notch edges
        let safeLeftMax = max(180, notchLeft - 45)
        let safeRightMin = min(screenWidth - 180, notchRight + 45)
        let safeRightMax = screenWidth - 80

        var chosenX: Float = 100
        if myIndex == 0 {
            let maxBound = max(100, safeLeftMax * 0.48)
            chosenX = Float.random(in: 80..<maxBound)
        } else if myIndex == 1 {
            let minBound = safeLeftMax * 0.52
            chosenX = Float.random(in: minBound..<safeLeftMax)
        } else {
            chosenX = Float.random(in: safeRightMin..<safeRightMax)
        }

        return chosenX
    }

    /// Updates this cat's position in shared memory and computes repulsion vectors from neighbors.
    public func updatePosition(x: Float, y: Float) -> (Float, Float) {
        let now = Date().timeIntervalSinceReferenceDate
        var slots = [SwarmSlot](repeating: SwarmSlot(x: 0, y: 0, time: 0), count: 8)
        
        let fd = open(path, O_RDWR | O_CREAT, 0o666)
        if fd >= 0 {
            let totalBytes = MemoryLayout<SwarmSlot>.stride * 8
            _ = read(fd, &slots, totalBytes)
            
            slots[myIndex] = SwarmSlot(x: x, y: y, time: now)
            
            lseek(fd, 0, SEEK_SET)
            _ = write(fd, &slots, totalBytes)
            close(fd)
        }

        var pushX: Float = 0
        var pushY: Float = 0
        let minDistance: Float = 55.0

        for i in 0..<8 {
            if i == myIndex { continue }
            let other = slots[i]
            if now - other.time < 0.5 {
                let dx = x - other.x
                let dy = y - other.y
                let dist = (dx * dx + dy * dy).squareRoot()
                if dist > 0.1 && dist < minDistance {
                    let force = (minDistance - dist) / minDistance
                    pushX += (dx / dist) * force * 10.0
                    pushY += (dy / dist) * force * 10.0
                }
            }
        }
        return (pushX, pushY)
    }
}
