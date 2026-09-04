import AppKit

@MainActor
enum MenuBarIcon {
    static let image: NSImage = {
        let size = NSSize(width: 18, height: 18)
        let scale: CGFloat = 18.0 / 24.0

        let image = NSImage(size: size, flipped: false) { _ in
            NSColor.black.setStroke()

            let outline = NSBezierPath(
                roundedRect: NSRect(
                    x: 2.5 * scale,
                    y: 6 * scale,
                    width: 19 * scale,
                    height: 12 * scale
                ),
                xRadius: 6 * scale,
                yRadius: 6 * scale
            )
            outline.lineWidth = 2 * scale
            outline.stroke()

            NSColor.black.setFill()

            let leftNostril = NSBezierPath(
                ovalIn: NSRect(
                    x: (9 - 1.5) * scale,
                    y: (12 - 2.2) * scale,
                    width: 3 * scale,
                    height: 4.4 * scale
                )
            )
            leftNostril.fill()

            let rightNostril = NSBezierPath(
                ovalIn: NSRect(
                    x: (15 - 1.5) * scale,
                    y: (12 - 2.2) * scale,
                    width: 3 * scale,
                    height: 4.4 * scale
                )
            )
            rightNostril.fill()

            return true
        }

        image.isTemplate = true
        return image
    }()
}
