import SwiftUI
import CoreImage

/// Interactive item that can be dragged, scaled, and rotated
/// Only responds to touches on opaque (visible) pixels
struct DraggableResizableItem: View {
    @Binding var item: CollageItem
    @Binding var selectedItemID: UUID?
    @State private var dragOffset: CGSize = .zero
    @State private var currentScale: CGFloat = 1.0
    @State private var rotation: Angle = .zero
    @State private var lastRotation: Angle = .zero
    @State private var isGestureActive: Bool = false

    var body: some View {
        GeometryReader { geometry in
            let displaySize = CGSize(
                width: item.size.width * item.scale * currentScale,
                height: item.size.height * item.scale * currentScale
            )

            ZStack {
                if let uiImage = item.uiImage,
                   let borderColor = item.cutoutBorderColor.color {
                    let borderScale = uiImage.size.width > 0 ? (displaySize.width / uiImage.size.width) : 1
                    let borderPadding = Constants.UI.cutoutBorderWidth * borderScale
                    CutoutBorderView(
                        uiImage: uiImage,
                        color: borderColor,
                        lineWidth: Constants.UI.cutoutBorderWidth
                    )
                    .frame(
                        width: displaySize.width + borderPadding * 2,
                        height: displaySize.height + borderPadding * 2
                    )
                    .allowsHitTesting(false)
                }

                item.image
                    .resizable()
                    .scaledToFit()
            }
            .frame(width: displaySize.width, height: displaySize.height)
            .rotationEffect(rotation)
            .overlay(
                Rectangle()
                    .stroke(Color.white, lineWidth: 2)
                    .opacity(selectedItemID == item.id ? 1 : 0)
            )
            .offset(dragOffset)
            .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
                            print("👆 [Gesture] Drag gesture changed")
                            print("📍 [Gesture] Touch location: \(value.startLocation)")
                            print("🔄 [Gesture] Gesture active: \(isGestureActive)")

                            // On first touch, validate if we're touching an opaque pixel
                            if !isGestureActive {
                                print("🆕 [Gesture] First touch - validating hit test...")

                                if let uiImage = item.uiImage {
                                    print("✅ [Gesture] UIImage found: \(uiImage.size)")

                                    let result = isTouchingOpaquePixel(
                                        at: value.startLocation,
                                        in: geometry,
                                        image: uiImage
                                    )

                                    print("📊 [Gesture] Hit test result: \(result)")

                                    if result {
                                        isGestureActive = true
                                        selectedItemID = item.id
                                        print("✅ [Gesture] Gesture ACTIVATED")
                                    } else {
                                        print("❌ [Gesture] Gesture REJECTED (transparent pixel)")
                                        return
                                    }
                                } else {
                                    print("⚠️ [Gesture] No UIImage in item - defaulting to active")
                                    isGestureActive = true
                                    selectedItemID = item.id
                                }
                            }

                            if isGestureActive {
                                dragOffset = value.translation
                                print("↔️ [Gesture] Drag offset updated: \(dragOffset)")
                            }
                        }
                        .onEnded { value in
                            print("🏁 [Gesture] Drag gesture ended")
                            if isGestureActive {
                                let newPosition = CGPoint(
                                    x: item.position.x + value.translation.width,
                                    y: item.position.y + value.translation.height
                                )
                                print("📍 [Gesture] New position: \(newPosition)")
                                item.position = newPosition
                                dragOffset = .zero
                                isGestureActive = false
                                print("✅ [Gesture] Gesture deactivated")
                            } else {
                                print("⏭️ [Gesture] Gesture was not active, no update")
                            }
                            print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
                        }
                )
                .simultaneousGesture(
                    MagnificationGesture()
                        .onChanged { value in
                            currentScale = value
                            print("🔍 [Gesture] Magnification: \(value)")
                        }
                        .onEnded { value in
                            item.scale *= value
                            currentScale = 1.0
                            print("✅ [Gesture] Magnification ended: final scale = \(item.scale)")
                        }
                )
                .simultaneousGesture(
                    RotationGesture()
                        .onChanged { value in
                            rotation = lastRotation + value
                            print("🔄 [Gesture] Rotation: \(rotation.degrees)°")
                        }
                        .onEnded { value in
                            lastRotation += value
                            print("✅ [Gesture] Rotation ended: \(lastRotation.degrees)°")
                        }
                )
        }
        .frame(width: item.size.width * item.scale * currentScale, height: item.size.height * item.scale * currentScale)
    }

    /// Checks if a touch location is on an opaque pixel of the image
    private func isTouchingOpaquePixel(at location: CGPoint, in geometry: GeometryProxy, image: UIImage) -> Bool {
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        print("🎯 [PixelCheck] Checking pixel opacity")
        print("📍 [PixelCheck] Touch location: \(location)")

        // Get the frame of the rendered image
        let imageWidth = item.size.width * item.scale * currentScale
        let imageHeight = item.size.height * item.scale * currentScale

        print("📐 [PixelCheck] Rendered image size: \(imageWidth) x \(imageHeight)")
        print("📐 [PixelCheck] Item size: \(item.size)")
        print("📐 [PixelCheck] Item scale: \(item.scale)")
        print("📐 [PixelCheck] Current scale: \(currentScale)")

        // Convert touch location to image-relative coordinates
        let touchX = location.x
        let touchY = location.y

        print("📍 [PixelCheck] Touch X: \(touchX), Y: \(touchY)")

        // Check bounds
        guard touchX >= 0, touchX <= imageWidth,
              touchY >= 0, touchY <= imageHeight else {
            print("❌ [PixelCheck] Touch outside image bounds")
            return false
        }

        // Convert to normalized coordinates (0-1)
        let normalizedX = touchX / imageWidth
        let normalizedY = touchY / imageHeight

        print("📊 [PixelCheck] Normalized coordinates: (\(normalizedX), \(normalizedY))")

        // Check if pixel is opaque
        let result = image.isOpaqueAt(normalizedPoint: CGPoint(x: normalizedX, y: normalizedY))
        print("📊 [PixelCheck] Final result: \(result)")

        return result
    }
}

private struct CutoutBorderView: View {
    let uiImage: UIImage
    let color: Color
    let lineWidth: CGFloat
    private let ciContext = CIContext()
    private static let thresholdKernel = CIColorKernel(
        source: """
        kernel vec4 thresholdMask(__sample s, float threshold) {
            float m = s.a >= threshold ? 1.0 : 0.0;
            return vec4(m, m, m, m);
        }
        """
    )

    var body: some View {
        if let borderImage = makeBorderImage() {
            Image(uiImage: borderImage)
                .resizable()
                .scaledToFit()
        }
    }

    private func makeBorderImage() -> UIImage? {
        guard let input = CIImage(image: uiImage) else { return nil }
        let pixelLineWidth = max(1, lineWidth * uiImage.scale)
        let alphaThreshold: CGFloat = 0.2
        let borderAlphaThreshold: CGFloat = 0.1
        let paddedExtent = input.extent.insetBy(dx: -pixelLineWidth, dy: -pixelLineWidth)
        let clearPadding = CIImage(color: CIColor(red: 0, green: 0, blue: 0, alpha: 0))
            .cropped(to: paddedExtent)
        let paddedInput = input.composited(over: clearPadding)

        let alphaMatrix = CIFilter.colorMatrix()
        alphaMatrix.inputImage = paddedInput
        alphaMatrix.rVector = CIVector(x: 0, y: 0, z: 0, w: 1)
        alphaMatrix.gVector = CIVector(x: 0, y: 0, z: 0, w: 1)
        alphaMatrix.bVector = CIVector(x: 0, y: 0, z: 0, w: 1)
        alphaMatrix.aVector = CIVector(x: 0, y: 0, z: 0, w: 1)
        guard let alphaMask = alphaMatrix.outputImage,
              let thresholdKernel = Self.thresholdKernel,
              let thresholdedMask = thresholdKernel.apply(
                extent: paddedExtent,
                arguments: [alphaMask, alphaThreshold]
              ) else { return nil }

        let dilation = CIFilter.morphologyMaximum()
        dilation.inputImage = thresholdedMask
        dilation.radius = Float(pixelLineWidth)
        guard let dilated = dilation.outputImage else { return nil }

        let difference = CIFilter.differenceBlendMode()
        difference.inputImage = dilated
        difference.backgroundImage = thresholdedMask
        guard let outlined = difference.outputImage else { return nil }

        // Use the outline luminance as alpha so we only draw the edge.
        let maskToAlpha = CIFilter.maskToAlpha()
        maskToAlpha.inputImage = outlined
        guard let borderMask = maskToAlpha.outputImage?.cropped(to: paddedExtent),
              let thresholdKernel = Self.thresholdKernel,
              let binaryBorderMask = thresholdKernel.apply(
                extent: paddedExtent,
                arguments: [borderMask, borderAlphaThreshold]
              ) else { return nil }

        let rgba = UIColor(color).cgColor.components ?? [1, 1, 1, 1]
        let borderColor = CIColor(
            red: rgba[0],
            green: rgba[1],
            blue: rgba[2],
            alpha: 1
        )
        let colorImage = CIImage(color: borderColor).cropped(to: paddedExtent)
        let clearImage = CIImage(color: CIColor(red: 0, green: 0, blue: 0, alpha: 0))
            .cropped(to: paddedExtent)
        let blend = CIFilter.blendWithAlphaMask()
        blend.inputImage = colorImage
        blend.backgroundImage = clearImage
        blend.maskImage = binaryBorderMask

        guard let colored = blend.outputImage,
              let cgImage = ciContext.createCGImage(colored, from: paddedExtent) else {
            return nil
        }

        return UIImage(cgImage: cgImage, scale: uiImage.scale, orientation: .up)
    }
}
