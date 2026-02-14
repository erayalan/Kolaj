import Foundation
import SwiftUI
import PhotosUI

/// Protocol for image processing services
protocol ImageProcessingProtocol {
    func processPickedItems(
        _ items: [PhotosPickerItem],
        canvasSize: CGSize,
        backgroundRemovalService: BackgroundRemovalProtocol
    ) async -> [CollageItem]
}

/// Service for processing and preparing images for the canvas
final class ImageProcessingService: ImageProcessingProtocol {

    /// Shared singleton instance
    static let shared = ImageProcessingService()

    private init() {}

    /// Processes picked photo items into CollageItem models
    /// - Parameters:
    ///   - items: PhotosPickerItems from the picker
    ///   - canvasSize: Current canvas size for calculating initial item size
    ///   - backgroundRemovalService: Service to use for background removal
    /// - Returns: Array of CollageItems ready to be added to the canvas
    func processPickedItems(
        _ items: [PhotosPickerItem],
        canvasSize: CGSize,
        backgroundRemovalService: BackgroundRemovalProtocol = BackgroundRemovalService.shared
    ) async -> [CollageItem] {
        guard !items.isEmpty else { return [] }

        var createdItems: [CollageItem] = []

        for item in items {
            // Load the image data
            guard let data = try? await item.loadTransferable(type: Data.self),
                  let rawUIImage = UIImage(data: data) else {
                continue
            }

            // Normalize orientation to .up so SwiftUI displays correctly
            let normalized = rawUIImage.fixedOrientation()

            // Remove background using Vision; fall back to normalized if it fails
            let finalUIImage: UIImage
            let backgroundRemovalResult = await backgroundRemovalService.removeBackground(from: normalized)
            switch backgroundRemovalResult {
            case .success(let processedImage):
                finalUIImage = processedImage
            case .failure:
                // Fall back to normalized image on error
                finalUIImage = normalized
            }

            // Trim fully transparent borders to the smallest non-transparent bounding box
            let trimmedUIImage = cropToNonTransparentArea(finalUIImage) ?? finalUIImage

            // Compute initial size: target height ~ 1/3 of canvas height, preserve aspect ratio
            let initialSize = calculateInitialSize(for: trimmedUIImage.size, canvasSize: canvasSize)

            // Create CollageItem
            let collageItem = CollageItem(
                id: UUID(),
                image: Image(uiImage: trimmedUIImage),
                size: initialSize,
                position: CGPoint(x: canvasSize.width / 2, y: canvasSize.height / 2),
                uiImage: trimmedUIImage
            )

            createdItems.append(collageItem)
        }

        return createdItems
    }

    // MARK: - Private Helpers

    /// Crops an image to the bounding box of non-transparent pixels (alpha > threshold)
    /// - Parameters:
    ///   - image: Source image with transparency
    ///   - alphaThreshold: Minimum alpha to consider a pixel as non-transparent (0-255)
    /// - Returns: Cropped UIImage or nil if no non-transparent pixels found
    private func cropToNonTransparentArea(_ image: UIImage, alphaThreshold: UInt8 = 1) -> UIImage? {
        guard let cgImage = image.cgImage else { return nil }

        let width = cgImage.width
        let height = cgImage.height
        guard width > 0, height > 0 else { return nil }

        let bytesPerPixel = 4
        let bitsPerComponent = 8
        let bytesPerRow = bytesPerPixel * width

        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGBitmapInfo.byteOrder32Big.union(CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue))

        guard let context = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: bitsPerComponent,
            bytesPerRow: bytesPerRow,
            space: colorSpace,
            bitmapInfo: bitmapInfo.rawValue
        ) else {
            return nil
        }

        // Draw the image into the RGBA context
        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
        guard let data = context.data else { return nil }

        let ptr = data.bindMemory(to: UInt8.self, capacity: height * bytesPerRow)

        var minX = width
        var minY = height
        var maxX = -1
        var maxY = -1

        // Scan for non-transparent pixels
        for y in 0..<height {
            let rowStart = y * bytesPerRow
            for x in 0..<width {
                let idx = rowStart + x * bytesPerPixel
                let alpha = ptr[idx + 3]
                if alpha > alphaThreshold {
                    if x < minX { minX = x }
                    if x > maxX { maxX = x }
                    if y < minY { minY = y }
                    if y > maxY { maxY = y }
                }
            }
        }

        // No non-transparent pixels found
        guard maxX >= 0, maxY >= 0 else { return nil }

        let cropRect = CGRect(
            x: minX,
            y: minY,
            width: max(1, maxX - minX + 1),
            height: max(1, maxY - minY + 1)
        )

        // Create a CGImage from the drawn context and crop using the same pixel space
        guard let fullImage = context.makeImage(), let cropped = fullImage.cropping(to: cropRect) else {
            return nil
        }

        return UIImage(cgImage: cropped, scale: image.scale, orientation: .up)
    }

    /// Calculates the initial size for an image based on canvas size
    /// - Parameters:
    ///   - imageSize: Original image size
    ///   - canvasSize: Canvas size
    /// - Returns: Calculated initial size preserving aspect ratio
    private func calculateInitialSize(for imageSize: CGSize, canvasSize: CGSize) -> CGSize {
        let targetHeight = max(
            Constants.Layout.minImageHeight,
            canvasSize.height * Constants.Layout.initialImageHeightFraction
        )

        let aspect = imageSize.width > 0 ? (imageSize.width / imageSize.height) : 1
        let targetWidth = targetHeight * aspect

        return CGSize(width: targetWidth, height: targetHeight)
    }
}
