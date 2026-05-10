import AppKit

enum StatusBarIcon {
    static func make() -> NSImage {
        let size = NSSize(width: 20, height: 18)
        let image = NSImage(size: size)

        image.lockFocus()
        defer { image.unlockFocus() }

        NSColor.clear.setFill()
        NSRect(origin: .zero, size: size).fill()
        let kanaText = UnicodeScalar(0x3042).map { String($0) } ?? "K"

        drawKey(
            rect: NSRect(x: 1.5, y: 7.0, width: 10.5, height: 9.0),
            text: "A",
            fontSize: 7.5
        )
        drawKey(
            rect: NSRect(x: 8.0, y: 2.0, width: 10.5, height: 9.0),
            text: kanaText,
            fontSize: 7.0
        )

        image.isTemplate = true
        return image
    }

    private static func drawKey(rect: NSRect, text: String, fontSize: CGFloat) {
        let path = NSBezierPath(roundedRect: rect, xRadius: 2.4, yRadius: 2.4)
        NSColor.black.withAlphaComponent(0.22).setFill()
        path.fill()
        NSColor.black.setStroke()
        path.lineWidth = 1.4
        path.stroke()

        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .center

        let attributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.monospacedSystemFont(ofSize: fontSize, weight: .bold),
            .foregroundColor: NSColor.black,
            .paragraphStyle: paragraphStyle,
        ]

        let textRect = NSRect(
            x: rect.minX,
            y: rect.minY + (rect.height - fontSize) * 0.5 - 0.8,
            width: rect.width,
            height: fontSize + 2
        )
        text.draw(in: textRect, withAttributes: attributes)
    }
}
