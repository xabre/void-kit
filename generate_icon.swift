#!/usr/bin/env swift

import AppKit
import CoreGraphics

// Generate the VoidKit icon at a given pixel size
func generateIcon(size: Int) -> NSImage {
    let s = CGFloat(size)
    // Create a bitmap at exact pixel dimensions (avoid Retina doubling)
    let rep = NSBitmapImageRep(
        bitmapDataPlanes: nil,
        pixelsWide: size, pixelsHigh: size,
        bitsPerSample: 8, samplesPerPixel: 4,
        hasAlpha: true, isPlanar: false,
        colorSpaceName: .deviceRGB,
        bytesPerRow: 0, bitsPerPixel: 0
    )!
    rep.size = NSSize(width: s, height: s)

    let nsCtx = NSGraphicsContext(bitmapImageRep: rep)!
    NSGraphicsContext.current = nsCtx
    let ctx = nsCtx.cgContext

    let rect = CGRect(x: 0, y: 0, width: s, height: s)
    let cornerRadius = s * 0.22 // macOS icon corner radius

    // --- Background: dark gradient ---
    let bgPath = CGPath(roundedRect: rect.insetBy(dx: s * 0.01, dy: s * 0.01),
                        cornerWidth: cornerRadius, cornerHeight: cornerRadius,
                        transform: nil)
    ctx.addPath(bgPath)
    ctx.clip()

    let colorSpace = CGColorSpaceCreateDeviceRGB()
    let bgColors = [
        CGColor(red: 0.10, green: 0.10, blue: 0.18, alpha: 1.0),
        CGColor(red: 0.04, green: 0.04, blue: 0.08, alpha: 1.0),
    ]
    if let gradient = CGGradient(colorsSpace: colorSpace, colors: bgColors as CFArray, locations: [0.0, 1.0]) {
        ctx.drawLinearGradient(gradient,
                               start: CGPoint(x: s * 0.5, y: s),
                               end: CGPoint(x: s * 0.5, y: 0),
                               options: [])
    }

    // --- Subtle border glow ---
    ctx.resetClip()
    let borderPath = CGPath(roundedRect: rect.insetBy(dx: s * 0.01, dy: s * 0.01),
                            cornerWidth: cornerRadius, cornerHeight: cornerRadius,
                            transform: nil)
    ctx.addPath(borderPath)
    ctx.setStrokeColor(CGColor(red: 0.3, green: 0.3, blue: 0.5, alpha: 0.4))
    ctx.setLineWidth(s * 0.005)
    ctx.strokePath()

    let cx = s * 0.5
    let cy = s * 0.5

    // --- Outer vortex rings (concentric circles fading out) ---
    for i in 0..<5 {
        let frac = CGFloat(i) / 5.0
        let ringRadius = s * (0.18 + frac * 0.18)
        let alpha = 0.15 * (1.0 - frac)
        ctx.setStrokeColor(CGColor(red: 0.4, green: 0.5, blue: 0.9, alpha: alpha))
        ctx.setLineWidth(s * 0.004)
        ctx.addEllipse(in: CGRect(x: cx - ringRadius, y: cy - ringRadius,
                                   width: ringRadius * 2, height: ringRadius * 2))
        ctx.strokePath()
    }

    // --- Central void: radial gradient from deep purple center to transparent ---
    let voidRadius = s * 0.28
    let voidRect = CGRect(x: cx - voidRadius, y: cy - voidRadius,
                          width: voidRadius * 2, height: voidRadius * 2)

    let voidColors = [
        CGColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 1.0),
        CGColor(red: 0.15, green: 0.1, blue: 0.35, alpha: 0.9),
        CGColor(red: 0.25, green: 0.2, blue: 0.55, alpha: 0.4),
        CGColor(red: 0.3, green: 0.3, blue: 0.6, alpha: 0.0),
    ]
    if let radGrad = CGGradient(colorsSpace: colorSpace, colors: voidColors as CFArray,
                                 locations: [0.0, 0.35, 0.7, 1.0]) {
        ctx.drawRadialGradient(radGrad,
                               startCenter: CGPoint(x: cx, y: cy), startRadius: 0,
                               endCenter: CGPoint(x: cx, y: cy), endRadius: voidRadius,
                               options: [])
    }

    // --- Swirl arms (4 curved arcs suggesting rotation) ---
    for arm in 0..<4 {
        let baseAngle = CGFloat(arm) * .pi / 2.0
        ctx.saveGState()
        ctx.translateBy(x: cx, y: cy)
        ctx.rotate(by: baseAngle)

        let armPath = CGMutablePath()
        let startR = s * 0.08
        let endR = s * 0.32
        var points: [CGPoint] = []

        for step in 0..<30 {
            let t = CGFloat(step) / 29.0
            let r = startR + (endR - startR) * t
            let angle = t * .pi * 0.7 // spiral sweep
            let x = r * cos(angle)
            let y = r * sin(angle)
            points.append(CGPoint(x: x, y: y))
        }

        armPath.move(to: points[0])
        for i in 1..<points.count {
            armPath.addLine(to: points[i])
        }

        ctx.addPath(armPath)
        let armAlpha = 0.5
        ctx.setStrokeColor(CGColor(red: 0.45, green: 0.55, blue: 1.0, alpha: armAlpha))
        ctx.setLineWidth(s * 0.012)
        ctx.setLineCap(.round)
        ctx.strokePath()

        ctx.restoreGState()
    }

    // --- Inner bright ring ---
    let innerRingRadius = s * 0.10
    ctx.setStrokeColor(CGColor(red: 0.5, green: 0.6, blue: 1.0, alpha: 0.6))
    ctx.setLineWidth(s * 0.008)
    ctx.addEllipse(in: CGRect(x: cx - innerRingRadius, y: cy - innerRingRadius,
                               width: innerRingRadius * 2, height: innerRingRadius * 2))
    ctx.strokePath()

    // --- Center dot glow ---
    let dotColors = [
        CGColor(red: 0.6, green: 0.7, blue: 1.0, alpha: 0.8),
        CGColor(red: 0.4, green: 0.4, blue: 0.8, alpha: 0.0),
    ]
    if let dotGrad = CGGradient(colorsSpace: colorSpace, colors: dotColors as CFArray,
                                 locations: [0.0, 1.0]) {
        ctx.drawRadialGradient(dotGrad,
                               startCenter: CGPoint(x: cx, y: cy), startRadius: 0,
                               endCenter: CGPoint(x: cx, y: cy), endRadius: s * 0.04,
                               options: [])
    }

    // --- "V" letter subtly integrated ---
    let fontSize = s * 0.22
    let font = NSFont.systemFont(ofSize: fontSize, weight: .bold)
    let vStr = NSAttributedString(string: "V", attributes: [
        .font: font,
        .foregroundColor: NSColor(red: 0.6, green: 0.7, blue: 1.0, alpha: 0.7),
    ])
    let vSize = vStr.size()
    let vOrigin = CGPoint(x: cx - vSize.width / 2, y: cy - vSize.height / 2 - s * 0.01)
    vStr.draw(at: vOrigin)

    NSGraphicsContext.current = nil
    let image = NSImage(size: NSSize(width: s, height: s))
    image.addRepresentation(rep)
    return image
}

func savePNG(_ image: NSImage, to path: String) {
    guard let tiffData = image.tiffRepresentation,
          let bitmap = NSBitmapImageRep(data: tiffData),
          let pngData = bitmap.representation(using: .png, properties: [:]) else {
        print("Failed to create PNG for \(path)")
        return
    }
    do {
        try pngData.write(to: URL(fileURLWithPath: path))
        print("Saved: \(path)")
    } catch {
        print("Error saving \(path): \(error)")
    }
}

// macOS icon sizes: point size x scale
let iconSpecs: [(points: Int, scale: Int)] = [
    (16, 1), (16, 2),
    (32, 1), (32, 2),
    (128, 1), (128, 2),
    (256, 1), (256, 2),
    (512, 1), (512, 2),
]

let outputDir = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] :
    "/Users/secelead/Projects/void-kit/VoidKit/VoidKit/Assets.xcassets/AppIcon.appiconset"

// Generate all sizes
var contentsImages: [[String: Any]] = []

for spec in iconSpecs {
    let pixels = spec.points * spec.scale
    let scaleStr = "\(spec.scale)x"
    let filename = "icon_\(spec.points)x\(spec.points)@\(scaleStr).png"

    let icon = generateIcon(size: pixels)
    savePNG(icon, to: "\(outputDir)/\(filename)")

    contentsImages.append([
        "filename": filename,
        "idiom": "mac",
        "scale": scaleStr,
        "size": "\(spec.points)x\(spec.points)",
    ])
}

// Write Contents.json
let contentsJSON: [String: Any] = [
    "images": contentsImages,
    "info": [
        "author": "xcode",
        "version": 1,
    ],
]

if let jsonData = try? JSONSerialization.data(withJSONObject: contentsJSON, options: [.prettyPrinted, .sortedKeys]) {
    let jsonPath = "\(outputDir)/Contents.json"
    try? jsonData.write(to: URL(fileURLWithPath: jsonPath))
    print("Saved: \(jsonPath)")
}

print("Done! Icon generated for VoidKit.")
