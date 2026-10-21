import AppKit

/// Explicit pixel dimensions avoid lockFocus's implicit screen scaling.
nonisolated enum IconRenderQuality {
    static func bitmap(_ icon: NSImage, side: CGFloat, scale: CGFloat) -> CGImage? {
        let pixels = max(16, Int((side * scale).rounded()))
        let format = CGBitmapInfo.floatComponents.rawValue | CGBitmapInfo.byteOrder16Little.rawValue
            | CGImageAlphaInfo.premultipliedLast.rawValue
        guard let colorSpace = CGColorSpace(name: CGColorSpace.extendedSRGB),
              let context = CGContext(data: nil, width: pixels, height: pixels,
                                      bitsPerComponent: 16, bytesPerRow: 0,
                                      space: colorSpace, bitmapInfo: format) else { return nil }
        NSGraphicsContext.saveGraphicsState()
        defer { NSGraphicsContext.restoreGraphicsState() }
        NSGraphicsContext.current = NSGraphicsContext(cgContext: context, flipped: false)
        NSGraphicsContext.current?.imageInterpolation = .high
        icon.draw(in: NSRect(x: 0, y: 0, width: pixels, height: pixels))
        return context.makeImage()
    }

    static func alignedOrigin(_ rect: CGRect, scale: CGFloat) -> CGRect {
        var result = aligned(rect, scale: scale)
        result.size = rect.size // Preserve line wrapping at the original label width.
        return result
    }

    static func aligned(_ rect: CGRect, scale: CGFloat) -> CGRect {
        CGRect(x: (rect.minX * scale).rounded() / scale,
               y: (rect.minY * scale).rounded() / scale,
               width: (rect.width * scale).rounded() / scale,
               height: (rect.height * scale).rounded() / scale)
    }
}
