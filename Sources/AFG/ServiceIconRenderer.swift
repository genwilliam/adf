import AppKit

enum ServiceIconRenderer {
    static func icnsData(for service: Service) -> Data {
        var body = Data()
        for (type, size) in [("ic08", 256.0), ("ic09", 512.0), ("ic10", 1024.0)] {
            let png = pngData(for: service, size: size)
            guard !png.isEmpty else { continue }
            body.append(type.data(using: .ascii) ?? Data())
            var length = UInt32(png.count + 8).bigEndian
            withUnsafeBytes(of: &length) { body.append(contentsOf: $0) }
            body.append(png)
        }

        var data = Data("icns".utf8)
        var total = UInt32(8 + body.count).bigEndian
        withUnsafeBytes(of: &total) { data.append(contentsOf: $0) }
        data.append(body)
        return data
    }

    static func pngData(for service: Service, size: CGFloat) -> Data {
        let pixels = Int(size)
        guard let bitmap = NSBitmapImageRep(bitmapDataPlanes: nil,
                                            pixelsWide: pixels,
                                            pixelsHigh: pixels,
                                            bitsPerSample: 8,
                                            samplesPerPixel: 4,
                                            hasAlpha: true,
                                            isPlanar: false,
                                            colorSpaceName: .deviceRGB,
                                            bytesPerRow: 0,
                                            bitsPerPixel: 0),
              let context = NSGraphicsContext(bitmapImageRep: bitmap) else {
            return Data()
        }

        bitmap.size = NSSize(width: size, height: size)
        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = context
        draw(service, in: NSRect(x: 0, y: 0, width: size, height: size))
        NSGraphicsContext.restoreGraphicsState()

        return bitmap.representation(using: .png, properties: [:]) ?? Data()
    }

    private static func draw(_ service: Service, in rect: NSRect) {
        let inset = rect.width * 0.094
        let iconRect = rect.insetBy(dx: inset, dy: inset)
        let size = iconRect.width
        let radius = size * 0.225
        let path = NSBezierPath(roundedRect: iconRect, xRadius: radius, yRadius: radius)

        if let icon = customIcon(for: service) {
            NSColor(white: 0.96, alpha: 1).setFill()
            path.fill()
            NSColor(white: 0, alpha: 0.10).setStroke()
            path.lineWidth = size * 0.008
            path.stroke()

            let iconInset = iconRect.insetBy(dx: size * 0.20, dy: size * 0.20)
            icon.draw(in: aspectFit(icon.size, in: iconInset), from: .zero, operation: .sourceOver, fraction: 1)
        } else {
            let base = NSColor(hex: service.colorHex)
            let light = base.blended(withFraction: 0.30, of: .white) ?? base
            NSGradient(starting: base, ending: light)?.draw(in: path, angle: -45)

            drawSymbol(service.symbol, in: iconRect.insetBy(dx: size * 0.26, dy: size * 0.26))
        }
    }

    private static func customIcon(for service: Service) -> NSImage? {
        guard service.iconFile != nil else { return nil }
        return IconCache.image(for: service.id)
    }

    private static func drawSymbol(_ name: String, in rect: NSRect) {
        guard let base = NSImage(systemSymbolName: name, accessibilityDescription: nil),
              let symbol = base.withSymbolConfiguration(
                NSImage.SymbolConfiguration(pointSize: rect.height * 0.9, weight: .semibold)
              ) else {
            return
        }

        let layer = NSImage(size: rect.size)
        layer.lockFocus()
        symbol.draw(in: aspectFit(symbol.size, in: NSRect(origin: .zero, size: rect.size)),
                    from: .zero, operation: .sourceOver, fraction: 1)
        NSColor.white.set()
        NSRect(origin: .zero, size: rect.size).fill(using: .sourceAtop)
        layer.unlockFocus()

        layer.draw(in: rect, from: .zero, operation: .sourceOver, fraction: 1)
    }

    private static func aspectFit(_ source: NSSize, in rect: NSRect) -> NSRect {
        guard source.width > 0, source.height > 0 else { return rect }
        let scale = min(rect.width / source.width, rect.height / source.height)
        let size = NSSize(width: source.width * scale, height: source.height * scale)
        return NSRect(x: rect.midX - size.width / 2,
                      y: rect.midY - size.height / 2,
                      width: size.width,
                      height: size.height)
    }
}

private extension NSColor {
    convenience init(hex: String) {
        let value = UInt64(hex.trimmingCharacters(in: CharacterSet(charactersIn: "#")), radix: 16) ?? 0x4285F4
        self.init(
            srgbRed: CGFloat((value >> 16) & 0xFF) / 255,
            green: CGFloat((value >> 8) & 0xFF) / 255,
            blue: CGFloat(value & 0xFF) / 255,
            alpha: 1
        )
    }
}
