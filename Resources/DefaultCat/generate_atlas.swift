#!/usr/bin/env swift
// Run: swift generate_atlas.swift
// Generates a 384x32 atlas.png with 12 frames of 32x32 pixel art cat.
import AppKit
import CoreGraphics

let frameW = 32, frameH = 32, frames = 12
let width  = frameW * frames
let height = frameH

let bitmapRep = NSBitmapImageRep(
    bitmapDataPlanes: nil,
    pixelsWide: width,
    pixelsHigh: height,
    bitsPerSample: 8,
    samplesPerPixel: 4,
    hasAlpha: true,
    isPlanar: false,
    colorSpaceName: .deviceRGB,
    bytesPerRow: width * 4,
    bitsPerPixel: 32
)!

NSGraphicsContext.saveGraphicsState()
guard let ctx = NSGraphicsContext(bitmapImageRep: bitmapRep) else { fatalError() }
NSGraphicsContext.current = ctx

func drawCat(frame: Int, offsetX: Int, phase: Int) {
    let ox = CGFloat(offsetX)
    let orange = NSColor(red: 1.0, green: 0.65, blue: 0.15, alpha: 1)
    let dark   = NSColor(red: 0.6,  green: 0.35, blue: 0.05, alpha: 1)
    let white  = NSColor.white
    let black  = NSColor.black
    let pink   = NSColor(red: 1.0,  green: 0.7,  blue: 0.75, alpha: 1)

    // Body
    orange.setFill()
    NSBezierPath(roundedRect: CGRect(x: ox+6, y: 4, width: 20, height: 16), xRadius: 4, yRadius: 4).fill()

    // Head
    orange.setFill()
    NSBezierPath(roundedRect: CGRect(x: ox+8, y: 16, width: 16, height: 14), xRadius: 5, yRadius: 5).fill()

    // Ears
    orange.setFill()
    let leftEar  = NSBezierPath(); leftEar.move(to: CGPoint(x: ox+9, y: 28)); leftEar.line(to: CGPoint(x: ox+11, y: 32)); leftEar.line(to: CGPoint(x: ox+14, y: 28)); leftEar.close(); leftEar.fill()
    let rightEar = NSBezierPath(); rightEar.move(to: CGPoint(x: ox+18, y: 28)); rightEar.line(to: CGPoint(x: ox+21, y: 32)); rightEar.line(to: CGPoint(x: ox+23, y: 28)); rightEar.close(); rightEar.fill()

    // Inner ears
    pink.setFill()
    let li = NSBezierPath(); li.move(to: CGPoint(x: ox+10, y: 28)); li.line(to: CGPoint(x: ox+11.5, y: 31)); li.line(to: CGPoint(x: ox+13, y: 28)); li.close(); li.fill()
    let ri = NSBezierPath(); ri.move(to: CGPoint(x: ox+19, y: 28)); ri.line(to: CGPoint(x: ox+20.5, y: 31)); ri.line(to: CGPoint(x: ox+22, y: 28)); ri.close(); ri.fill()

    // Eyes
    black.setFill()
    NSBezierPath(ovalIn: CGRect(x: ox+10, y: 22, width: 4, height: 4)).fill()
    NSBezierPath(ovalIn: CGRect(x: ox+18, y: 22, width: 4, height: 4)).fill()

    // Pupils
    white.setFill()
    NSBezierPath(ovalIn: CGRect(x: ox+11, y: 23, width: 2, height: 2)).fill()
    NSBezierPath(ovalIn: CGRect(x: ox+19, y: 23, width: 2, height: 2)).fill()

    // Nose
    pink.setFill()
    NSBezierPath(ovalIn: CGRect(x: ox+14, y: 19, width: 4, height: 3)).fill()

    // Mouth
    black.setStroke()
    let mouth = NSBezierPath()
    mouth.move(to: CGPoint(x: ox+16, y: 19))
    mouth.line(to: CGPoint(x: ox+14, y: 17))
    mouth.move(to: CGPoint(x: ox+16, y: 19))
    mouth.line(to: CGPoint(x: ox+18, y: 17))
    mouth.lineWidth = 0.5
    mouth.stroke()

    // Tail
    dark.setStroke()
    let tail = NSBezierPath()
    tail.move(to: CGPoint(x: ox+6, y: 8))
    tail.curve(to: CGPoint(x: ox+2, y: 16 + CGFloat(phase) * 3),
               controlPoint1: CGPoint(x: ox+2, y: 6),
               controlPoint2: CGPoint(x: ox+0, y: 12))
    tail.lineWidth = 3
    tail.stroke()

    // Legs (walk phase)
    dark.setFill()
    let legOffset = phase == 0 ? 0 : 2
    NSBezierPath(rect: CGRect(x: ox+8,  y: 2, width: 4, height: 4 + legOffset)).fill()
    NSBezierPath(rect: CGRect(x: ox+20, y: 2, width: 4, height: 4 - legOffset + 2)).fill()
}

// Frame 0: idle
drawCat(frame: 0, offsetX: 0, phase: 0)

// Frames 1-2: walk east
drawCat(frame: 1, offsetX: frameW * 1, phase: 0)
drawCat(frame: 2, offsetX: frameW * 2, phase: 1)

// Frames 3-4: walk west (mirror — just draw same but we'd flip in shader or just offset)
drawCat(frame: 3, offsetX: frameW * 3, phase: 0)
drawCat(frame: 4, offsetX: frameW * 4, phase: 1)

// Frames 5-6: walk north
drawCat(frame: 5, offsetX: frameW * 5, phase: 0)
drawCat(frame: 6, offsetX: frameW * 6, phase: 1)

// Frames 7-8: walk south
drawCat(frame: 7, offsetX: frameW * 7, phase: 0)
drawCat(frame: 8, offsetX: frameW * 8, phase: 1)

// Frames 9-10: sleep
NSColor(red: 0.9, green: 0.5, blue: 0.1, alpha: 1).setFill()
for f in [9, 10] {
    let ox = CGFloat(frameW * f)
    drawCat(frame: f, offsetX: frameW * f, phase: 0)
    // Z's
    NSColor.black.setStroke()
    let z = NSBezierPath()
    z.move(to: CGPoint(x: ox+22, y: 26))
    z.line(to: CGPoint(x: ox+26, y: 26))
    z.line(to: CGPoint(x: ox+22, y: 30))
    z.line(to: CGPoint(x: ox+26, y: 30))
    z.lineWidth = 1
    z.stroke()
}

// Frame 11: alert
drawCat(frame: 11, offsetX: frameW * 11, phase: 0)
NSColor.yellow.setFill()
NSBezierPath(ovalIn: CGRect(x: CGFloat(frameW * 11) + 14, y: 20, width: 4, height: 5)).fill()

NSGraphicsContext.restoreGraphicsState()

let outURL = URL(fileURLWithPath: CommandLine.arguments.dropFirst().first ?? "atlas.png")
if let data = bitmapRep.representation(using: .png, properties: [:]) {
    try! data.write(to: outURL)
    print("Atlas written to \(outURL.path)")
} else {
    print("Failed to create PNG")
}
