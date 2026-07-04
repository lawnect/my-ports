import AppKit
import Foundation

let outputPath = CommandLine.arguments.dropFirst().first ?? "Resources/AppIcon.png"
let size = CGSize(width: 1024, height: 1024)
let scale: CGFloat = 1

func color(_ red: CGFloat, _ green: CGFloat, _ blue: CGFloat, _ alpha: CGFloat = 1) -> NSColor {
    NSColor(red: red / 255, green: green / 255, blue: blue / 255, alpha: alpha)
}

func roundedRect(_ rect: CGRect, radius: CGFloat) -> NSBezierPath {
    NSBezierPath(roundedRect: rect, xRadius: radius, yRadius: radius)
}

func stroke(_ path: NSBezierPath, color: NSColor, width: CGFloat) {
    color.setStroke()
    path.lineWidth = width
    path.stroke()
}

func fill(_ path: NSBezierPath, color: NSColor) {
    color.setFill()
    path.fill()
}

func drawLinearGradient(in rect: CGRect, start: NSColor, end: NSColor, angle: CGFloat) {
    let gradient = NSGradient(starting: start, ending: end)
    gradient?.draw(in: rect, angle: angle)
}

func drawShadow(offset: CGSize, blur: CGFloat, color: NSColor, body: () -> Void) {
    NSGraphicsContext.current?.saveGraphicsState()
    let shadow = NSShadow()
    shadow.shadowOffset = offset
    shadow.shadowBlurRadius = blur
    shadow.shadowColor = color
    shadow.set()
    body()
    NSGraphicsContext.current?.restoreGraphicsState()
}

func drawPortRow(y: CGFloat, highlighted: Bool = false) {
    let rowRect = CGRect(x: 270, y: y, width: 484, height: 82)
    let row = roundedRect(rowRect, radius: 28)

    fill(row, color: highlighted ? color(30, 103, 220, 0.92) : color(20, 25, 32, 0.92))
    stroke(row, color: highlighted ? color(122, 183, 255, 0.75) : color(72, 82, 96, 0.55), width: 2)

    let slotColor = highlighted ? color(231, 246, 255) : color(174, 187, 202)
    let dimColor = highlighted ? color(185, 224, 255, 0.95) : color(90, 102, 116)

    for index in 0..<3 {
        let slot = roundedRect(
            CGRect(x: 310 + CGFloat(index) * 42, y: y + 25, width: 22, height: 32),
            radius: 8
        )
        fill(slot, color: slotColor)
    }

    fill(roundedRect(CGRect(x: 470, y: y + 28, width: 198, height: 10), radius: 5), color: dimColor)
    fill(roundedRect(CGRect(x: 470, y: y + 46, width: 140, height: 10), radius: 5), color: dimColor.withAlphaComponent(0.72))
}

let bitmap = NSBitmapImageRep(
    bitmapDataPlanes: nil,
    pixelsWide: Int(size.width * scale),
    pixelsHigh: Int(size.height * scale),
    bitsPerSample: 8,
    samplesPerPixel: 4,
    hasAlpha: true,
    isPlanar: false,
    colorSpaceName: .deviceRGB,
    bytesPerRow: 0,
    bitsPerPixel: 0
)!

NSGraphicsContext.saveGraphicsState()
NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: bitmap)
NSGraphicsContext.current?.imageInterpolation = .high

NSColor.clear.setFill()
CGRect(origin: .zero, size: size).fill()

let outerRect = CGRect(x: 72, y: 72, width: 880, height: 880)
let outerPath = roundedRect(outerRect, radius: 210)

drawShadow(offset: CGSize(width: 0, height: -26), blur: 48, color: color(0, 0, 0, 0.36)) {
    fill(outerPath, color: color(24, 29, 36))
}

outerPath.addClip()
drawLinearGradient(
    in: outerRect,
    start: color(49, 58, 69),
    end: color(13, 17, 22),
    angle: 90
)

fill(
    roundedRect(CGRect(x: 98, y: 612, width: 828, height: 246), radius: 170),
    color: color(255, 255, 255, 0.055)
)

stroke(outerPath, color: color(255, 255, 255, 0.16), width: 4)
stroke(roundedRect(outerRect.insetBy(dx: 18, dy: 18), radius: 192), color: color(0, 0, 0, 0.34), width: 3)

let panelRect = CGRect(x: 206, y: 214, width: 612, height: 596)
let panel = roundedRect(panelRect, radius: 84)

drawShadow(offset: CGSize(width: 0, height: -20), blur: 38, color: color(0, 0, 0, 0.42)) {
    fill(panel, color: color(12, 16, 22, 0.96))
}
stroke(panel, color: color(123, 137, 154, 0.42), width: 4)
stroke(roundedRect(panelRect.insetBy(dx: 16, dy: 16), radius: 66), color: color(255, 255, 255, 0.08), width: 2)

fill(
    roundedRect(CGRect(x: 284, y: 724, width: 456, height: 18), radius: 9),
    color: color(92, 112, 132, 0.42)
)

drawPortRow(y: 590)
drawPortRow(y: 470, highlighted: true)
drawPortRow(y: 350)

let lensCenter = CGPoint(x: 704, y: 338)
let lensRect = CGRect(x: lensCenter.x - 102, y: lensCenter.y - 102, width: 204, height: 204)
let lens = NSBezierPath(ovalIn: lensRect)

let handle = NSBezierPath()
handle.move(to: CGPoint(x: 774, y: 266))
handle.line(to: CGPoint(x: 838, y: 202))
handle.lineCapStyle = .round
stroke(handle, color: color(233, 241, 248, 0.92), width: 32)
stroke(handle, color: color(67, 155, 255, 0.86), width: 18)

drawShadow(offset: CGSize(width: 0, height: -12), blur: 28, color: color(0, 0, 0, 0.35)) {
    fill(lens, color: color(16, 22, 30, 0.97))
}
stroke(lens, color: color(233, 241, 248, 0.88), width: 16)
stroke(lens, color: color(67, 155, 255, 0.82), width: 5)

for index in 0..<3 {
    fill(
        roundedRect(
            CGRect(x: 650 + CGFloat(index) * 42, y: 322, width: 24, height: 44),
            radius: 9
        ),
        color: index == 1 ? color(86, 177, 255) : color(231, 248, 255, 0.9)
    )
}

NSGraphicsContext.restoreGraphicsState()

guard let data = bitmap.representation(using: .png, properties: [:]) else {
    fputs("Failed to encode PNG\n", stderr)
    exit(1)
}

let outputURL = URL(fileURLWithPath: outputPath)
try FileManager.default.createDirectory(
    at: outputURL.deletingLastPathComponent(),
    withIntermediateDirectories: true
)
try data.write(to: outputURL)
