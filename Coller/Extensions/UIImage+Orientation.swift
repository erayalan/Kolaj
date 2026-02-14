import UIKit

extension UIImage {
    /// Returns a new image with orientation normalized to .up
    /// This fixes display issues in SwiftUI where orientation metadata is not respected
    func fixedOrientation() -> UIImage {
        // Already correct orientation
        if imageOrientation == .up { return self }

        // Redraw the image in the correct orientation
        UIGraphicsBeginImageContextWithOptions(size, false, scale)
        defer { UIGraphicsEndImageContext() }
        draw(in: CGRect(origin: .zero, size: size))
        let normalized = UIGraphicsGetImageFromCurrentImageContext()
        return normalized ?? self
    }
}

extension UIImage.Orientation {
    /// Map UIImage.Orientation to EXIF orientation values used by Core Image
    var exifOrientation: UInt32 {
        switch self {
        case .up: return 1
        case .down: return 3
        case .left: return 8
        case .right: return 6
        case .upMirrored: return 2
        case .downMirrored: return 4
        case .leftMirrored: return 5
        case .rightMirrored: return 7
        @unknown default: return 1
        }
    }
}
