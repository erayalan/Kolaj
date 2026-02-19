import UIKit

extension UIImage {
    /// Checks if a point in the image (normalized 0-1 coordinates) has opaque pixels
    /// - Parameter point: Point in normalized coordinates (0-1, where 0,0 is top-left)
    /// - Returns: True if the pixel at that point is opaque (alpha > threshold)
    func isOpaqueAt(normalizedPoint point: CGPoint) -> Bool {
        guard let cgImage = self.cgImage else {
            return false
        }

        // Convert normalized coordinates to pixel coordinates
        let pixelX = Int(point.x * CGFloat(cgImage.width))
        let pixelY = Int(point.y * CGFloat(cgImage.height))

        // Bounds check
        guard pixelX >= 0, pixelX < cgImage.width,
              pixelY >= 0, pixelY < cgImage.height else {
            return false
        }

        // Get pixel data
        guard let dataProvider = cgImage.dataProvider,
              let data = dataProvider.data,
              let bytes = CFDataGetBytePtr(data) else {
            return false
        }

        let bytesPerPixel = cgImage.bitsPerPixel / 8
        let bytesPerRow = cgImage.bytesPerRow
        let pixelOffset = pixelY * bytesPerRow + pixelX * bytesPerPixel

        // Check alpha channel (usually last byte in RGBA)
        // Handle different pixel formats
        guard pixelOffset + bytesPerPixel <= CFDataGetLength(data) else {
            return false
        }

        let alphaOffset: Int
        let bitmapInfo = cgImage.bitmapInfo

        if bitmapInfo.contains(.alphaInfoMask) {
            let alphaInfo = CGImageAlphaInfo(rawValue: bitmapInfo.rawValue & CGBitmapInfo.alphaInfoMask.rawValue)

            switch alphaInfo {
            case .premultipliedLast, .last:
                alphaOffset = bytesPerPixel - 1
            case .premultipliedFirst, .first:
                alphaOffset = 0
            default:
                // No alpha channel, treat as opaque
                return true
            }
        } else {
            // No alpha info, treat as opaque
            return true
        }

        let alpha = bytes[pixelOffset + alphaOffset]

        // Consider pixel opaque if alpha > 25 (out of 255)
        return alpha > 25
    }
}
