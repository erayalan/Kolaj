import UIKit

extension UIImage {
    /// Checks if a point in the image (normalized 0-1 coordinates) has opaque pixels
    /// - Parameter point: Point in normalized coordinates (0-1, where 0,0 is top-left)
    /// - Returns: True if the pixel at that point is opaque (alpha > threshold)
    func isOpaqueAt(normalizedPoint point: CGPoint) -> Bool {
        print("🔍 [HitTest] Starting hit test at normalized point: \(point)")

        guard let cgImage = self.cgImage else {
            print("❌ [HitTest] Failed to get cgImage")
            return false
        }

        print("📐 [HitTest] Image size: \(cgImage.width) x \(cgImage.height)")

        // Convert normalized coordinates to pixel coordinates
        let pixelX = Int(point.x * CGFloat(cgImage.width))
        let pixelY = Int(point.y * CGFloat(cgImage.height))

        print("📍 [HitTest] Pixel coordinates: (\(pixelX), \(pixelY))")

        // Bounds check
        guard pixelX >= 0, pixelX < cgImage.width,
              pixelY >= 0, pixelY < cgImage.height else {
            print("❌ [HitTest] Out of bounds")
            return false
        }

        // Get pixel data
        guard let dataProvider = cgImage.dataProvider,
              let data = dataProvider.data,
              let bytes = CFDataGetBytePtr(data) else {
            print("❌ [HitTest] Failed to get pixel data")
            return false
        }

        let bytesPerPixel = cgImage.bitsPerPixel / 8
        let bytesPerRow = cgImage.bytesPerRow
        let pixelOffset = pixelY * bytesPerRow + pixelX * bytesPerPixel

        print("🔢 [HitTest] Bytes per pixel: \(bytesPerPixel), Bytes per row: \(bytesPerRow)")
        print("🔢 [HitTest] Pixel offset: \(pixelOffset)")

        // Check alpha channel (usually last byte in RGBA)
        // Handle different pixel formats
        guard pixelOffset + bytesPerPixel <= CFDataGetLength(data) else {
            print("❌ [HitTest] Offset out of data range")
            return false
        }

        let alphaOffset: Int
        let bitmapInfo = cgImage.bitmapInfo
        print("🎨 [HitTest] Bitmap info: \(bitmapInfo.rawValue)")

        if bitmapInfo.contains(.alphaInfoMask) {
            let alphaInfo = CGImageAlphaInfo(rawValue: bitmapInfo.rawValue & CGBitmapInfo.alphaInfoMask.rawValue)
            print("🎨 [HitTest] Alpha info: \(String(describing: alphaInfo))")

            switch alphaInfo {
            case .premultipliedLast, .last:
                alphaOffset = bytesPerPixel - 1
                print("✅ [HitTest] Alpha at end (offset: \(alphaOffset))")
            case .premultipliedFirst, .first:
                alphaOffset = 0
                print("✅ [HitTest] Alpha at beginning (offset: \(alphaOffset))")
            default:
                // No alpha channel, treat as opaque
                print("ℹ️ [HitTest] No alpha channel, treating as opaque")
                return true
            }
        } else {
            // No alpha info, treat as opaque
            print("ℹ️ [HitTest] No alpha info in bitmap, treating as opaque")
            return true
        }

        let alpha = bytes[pixelOffset + alphaOffset]
        print("🎭 [HitTest] Alpha value: \(alpha) / 255")

        // Consider pixel opaque if alpha > 25 (out of 255)
        let isOpaque = alpha > 25
        print("✅ [HitTest] Result: \(isOpaque ? "OPAQUE (interactive)" : "TRANSPARENT (pass-through)")")
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")

        return isOpaque
    }
}
