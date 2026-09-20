import AppKit

let directory = URL(fileURLWithPath: CommandLine.arguments[1])
try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
for points in [16, 32, 128, 256, 512] {
    for scale in [1, 2] {
        let size = points * scale
        let image = NSImage(size: NSSize(width: size, height: size))
        image.lockFocus()
        let transform = NSAffineTransform()
        transform.scale(by: CGFloat(size) / 512)
        transform.concat()
        let background = NSBezierPath(roundedRect: NSRect(x: 24, y: 24, width: 464, height: 464), xRadius: 110, yRadius: 110)
        NSGradient(starting: NSColor(srgbRed: 0.86, green: 0.95, blue: 0.96, alpha: 1),
                   ending: NSColor(srgbRed: 0.68, green: 0.78, blue: 0.96, alpha: 1))!.draw(in: background, angle: -70)
        let capsule = NSBezierPath(roundedRect: NSRect(x: 57, y: 148, width: 398, height: 217), xRadius: 96, yRadius: 96)
        NSColor.white.withAlphaComponent(0.84).setFill()
        capsule.fill()
        NSColor.white.setStroke()
        capsule.lineWidth = 3
        capsule.stroke()
        for index in 0..<10 {
            (index < 7 ? NSColor(srgbRed: 0.27, green: 0.69, blue: 0.44, alpha: 1) : NSColor.lightGray.withAlphaComponent(0.35)).setFill()
            NSBezierPath(roundedRect: NSRect(x: 100 + index * 32, y: 324, width: 25, height: 7), xRadius: 3.5, yRadius: 3.5).fill()
        }
        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = .center
        ("64%" as NSString).draw(in: NSRect(x: 78, y: 200, width: 356, height: 111), withAttributes: [
            .font: NSFont.monospacedDigitSystemFont(ofSize: 93, weight: .semibold),
            .foregroundColor: NSColor(srgbRed: 0.12, green: 0.18, blue: 0.27, alpha: 1),
            .paragraphStyle: paragraph
        ])
        NSColor.lightGray.withAlphaComponent(0.35).setFill()
        NSBezierPath(roundedRect: NSRect(x: 103, y: 184, width: 306, height: 7), xRadius: 3.5, yRadius: 3.5).fill()
        NSColor(srgbRed: 0.34, green: 0.55, blue: 0.93, alpha: 1).setFill()
        NSBezierPath(roundedRect: NSRect(x: 103, y: 184, width: 196, height: 7), xRadius: 3.5, yRadius: 3.5).fill()
        image.unlockFocus()
        let bitmap = NSBitmapImageRep(data: image.tiffRepresentation!)!
        let name = "icon_\(points)x\(points)" + (scale == 2 ? "@2x" : "") + ".png"
        try bitmap.representation(using: .png, properties: [:])!.write(to: directory.appendingPathComponent(name))
    }
}
