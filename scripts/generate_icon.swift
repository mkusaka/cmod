#!/usr/bin/swift
import AppKit

let outputDir = CommandLine.arguments.count > 1
    ? CommandLine.arguments[1]
    : "Cmod/Assets.xcassets/AppIcon.appiconset"

let iconSizes: [(pointSize: Int, scale: Int)] = [
    (16, 1), (16, 2),
    (32, 1), (32, 2),
    (128, 1), (128, 2),
    (256, 1), (256, 2),
    (512, 1), (512, 2),
]

func drawIcon(size: CGFloat) {
    let bounds = NSRect(x: 0, y: 0, width: size, height: size)
    NSColor.clear.setFill()
    bounds.fill()

    let backgroundRect = bounds.insetBy(dx: size * 0.035, dy: size * 0.035)
    let backgroundPath = NSBezierPath(
        roundedRect: backgroundRect,
        xRadius: size * 0.23,
        yRadius: size * 0.23
    )

    NSGraphicsContext.saveGraphicsState()
    backgroundPath.addClip()
    let gradient = NSGradient(colors: [
        NSColor(red: 0.08, green: 0.14, blue: 0.18, alpha: 1.0),
        NSColor(red: 0.00, green: 0.34, blue: 0.46, alpha: 1.0),
        NSColor(red: 0.10, green: 0.54, blue: 0.41, alpha: 1.0),
    ])!
    gradient.draw(in: backgroundRect, angle: 45)
    NSGraphicsContext.restoreGraphicsState()

    NSColor.white.withAlphaComponent(0.18).setStroke()
    backgroundPath.lineWidth = max(1, size * 0.012)
    backgroundPath.stroke()

    drawKey(
        rect: NSRect(
            x: size * 0.16,
            y: size * 0.47,
            width: size * 0.39,
            height: size * 0.30
        ),
        text: "A",
        fontSize: size * 0.17,
        size: size
    )

    drawKey(
        rect: NSRect(
            x: size * 0.45,
            y: size * 0.23,
            width: size * 0.39,
            height: size * 0.30
        ),
        text: String(UnicodeScalar(0x3042)!),
        fontSize: size * 0.15,
        size: size
    )

    drawArrow(size: size)
}

func drawKey(rect: NSRect, text: String, fontSize: CGFloat, size: CGFloat) {
    let shadow = NSShadow()
    shadow.shadowColor = NSColor.black.withAlphaComponent(0.25)
    shadow.shadowOffset = NSSize(width: 0, height: -size * 0.012)
    shadow.shadowBlurRadius = size * 0.035

    let path = NSBezierPath(
        roundedRect: rect,
        xRadius: size * 0.06,
        yRadius: size * 0.06
    )

    NSGraphicsContext.saveGraphicsState()
    shadow.set()
    NSColor.white.withAlphaComponent(0.96).setFill()
    path.fill()
    NSGraphicsContext.restoreGraphicsState()

    NSColor(red: 0.03, green: 0.11, blue: 0.13, alpha: 0.16).setStroke()
    path.lineWidth = max(1, size * 0.008)
    path.stroke()

    let paragraphStyle = NSMutableParagraphStyle()
    paragraphStyle.alignment = .center

    let attributes: [NSAttributedString.Key: Any] = [
        .font: NSFont.monospacedSystemFont(ofSize: fontSize, weight: .heavy),
        .foregroundColor: NSColor(red: 0.04, green: 0.17, blue: 0.19, alpha: 1.0),
        .paragraphStyle: paragraphStyle,
    ]

    let textRect = NSRect(
        x: rect.minX,
        y: rect.midY - fontSize * 0.58,
        width: rect.width,
        height: fontSize * 1.3
    )
    text.draw(in: textRect, withAttributes: attributes)
}

func drawArrow(size: CGFloat) {
    let path = NSBezierPath()
    path.move(to: NSPoint(x: size * 0.35, y: size * 0.38))
    path.line(to: NSPoint(x: size * 0.66, y: size * 0.62))

    NSColor(red: 1.00, green: 0.74, blue: 0.30, alpha: 0.95).setStroke()
    path.lineWidth = max(2, size * 0.035)
    path.lineCapStyle = .round
    path.stroke()

    let arrowHead = NSBezierPath()
    arrowHead.move(to: NSPoint(x: size * 0.66, y: size * 0.62))
    arrowHead.line(to: NSPoint(x: size * 0.58, y: size * 0.62))
    arrowHead.move(to: NSPoint(x: size * 0.66, y: size * 0.62))
    arrowHead.line(to: NSPoint(x: size * 0.63, y: size * 0.54))
    arrowHead.lineWidth = max(2, size * 0.035)
    arrowHead.lineCapStyle = .round
    arrowHead.stroke()
}

func generateIcon(pointSize: Int, scale: Int) throws {
    let pixelSize = pointSize * scale
    guard let rep = NSBitmapImageRep(
        bitmapDataPlanes: nil,
        pixelsWide: pixelSize,
        pixelsHigh: pixelSize,
        bitsPerSample: 8,
        samplesPerPixel: 4,
        hasAlpha: true,
        isPlanar: false,
        colorSpaceName: .deviceRGB,
        bytesPerRow: 0,
        bitsPerPixel: 0
    ) else {
        throw CocoaError(.coderInvalidValue)
    }

    rep.size = NSSize(width: pointSize, height: pointSize)

    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
    drawIcon(size: CGFloat(pointSize))
    NSGraphicsContext.restoreGraphicsState()

    guard let pngData = rep.representation(using: .png, properties: [:]) else {
        throw CocoaError(.fileWriteUnknown)
    }

    let filename = "icon_\(pointSize)x\(pointSize)@\(scale)x.png"
    let url = URL(fileURLWithPath: outputDir).appendingPathComponent(filename)
    try pngData.write(to: url)
    print("Generated \(filename)")
}

func writeContentsJSON() throws {
    let imageEntries = iconSizes.map { size in
        """
            {
              "filename" : "icon_\(size.pointSize)x\(size.pointSize)@\(size.scale)x.png",
              "idiom" : "mac",
              "scale" : "\(size.scale)x",
              "size" : "\(size.pointSize)x\(size.pointSize)"
            }
        """
    }.joined(separator: ",\n")

    let contents = """
    {
      "images" : [
    \(imageEntries)
      ],
      "info" : {
        "author" : "xcode",
        "version" : 1
      }
    }
    """

    let url = URL(fileURLWithPath: outputDir).appendingPathComponent("Contents.json")
    try (contents + "\n").write(to: url, atomically: true, encoding: .utf8)
    print("Updated Contents.json")
}

try FileManager.default.createDirectory(
    at: URL(fileURLWithPath: outputDir),
    withIntermediateDirectories: true
)

for iconSize in iconSizes {
    try generateIcon(pointSize: iconSize.pointSize, scale: iconSize.scale)
}

try writeContentsJSON()
