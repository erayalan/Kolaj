import Foundation
import UIKit
import Vision
import CoreImage.CIFilterBuiltins

enum BackgroundRemovalError: Error {
    case processingFailed
    case cgImageCreationFailed
    case maskCreationFailed
    case noObservations
}

/// Protocol for background removal services
protocol BackgroundRemovalProtocol {
    func removeBackground(from image: UIImage) async -> Result<UIImage, BackgroundRemovalError>
}

/// Service for removing backgrounds from images using Vision framework
final class BackgroundRemovalService: BackgroundRemovalProtocol {

    /// Shared singleton instance
    static let shared = BackgroundRemovalService()

    private let ciContext = CIContext(options: nil)

    private init() {}

    /// Removes the background of an image using on-device Vision segmentation.
    /// Uses CIImage and Vision framework for reliable background removal.
    /// - Returns: Result with UIImage with transparent background or error
    func removeBackground(from image: UIImage) async -> Result<UIImage, BackgroundRemovalError> {
        // Ensure we work with a correctly oriented CIImage
        guard let baseCI = CIImage(image: image) else {
            return .failure(.cgImageCreationFailed)
        }

        let orientedCI = baseCI.oriented(forExifOrientation: Int32(image.imageOrientation.exifOrientation))

        // Generate subject mask via Vision
        guard let maskCI = subjectMaskImage(from: orientedCI) else {
            return .failure(.maskCreationFailed)
        }

        // Apply mask to original oriented image
        let outputCI = apply(mask: maskCI, to: orientedCI)

        // Render to UIImage
        guard let result = render(ciImage: outputCI, orientation: image.imageOrientation) else {
            return .failure(.processingFailed)
        }

        return .success(result)
    }

    // MARK: - Private helpers

    private func subjectMaskImage(from inputImage: CIImage) -> CIImage? {
        let handler = VNImageRequestHandler(ciImage: inputImage)
        let request = VNGenerateForegroundInstanceMaskRequest()
        do {
            try handler.perform([request])
        } catch {
            print("Vision perform error: \(error)")
            return nil
        }
        guard let result = request.results?.first else {
            print("No observations found")
            return nil
        }
        do {
            let maskPixelBuffer = try result.generateScaledMaskForImage(forInstances: result.allInstances, from: handler)
            return CIImage(cvPixelBuffer: maskPixelBuffer)
        } catch {
            print("Mask generation error: \(error)")
            return nil
        }
    }

    private func apply(mask: CIImage, to image: CIImage) -> CIImage {
        let filter = CIFilter.blendWithMask()
        filter.inputImage = image
        filter.maskImage = mask
        filter.backgroundImage = CIImage.empty()
        return filter.outputImage ?? image
    }

    private func render(ciImage: CIImage, orientation: UIImage.Orientation = .up) -> UIImage? {
        guard let cgImage = ciContext.createCGImage(ciImage, from: ciImage.extent) else {
            return nil
        }
        return UIImage(cgImage: cgImage, scale: UIScreen.main.scale, orientation: orientation)
    }
}
