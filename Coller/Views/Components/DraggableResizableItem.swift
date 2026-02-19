import SwiftUI
import CoreImage

/// Interactive item that can be dragged, scaled, and rotated
/// Only responds to touches on opaque (visible) pixels
struct DraggableResizableItem: View {
    @Binding var item: CollageItem
    @Binding var selectedItemID: UUID?
    @Binding var isAnyItemDragging: Bool
    @State private var dragOffset: CGSize = .zero
    @State private var currentScale: CGFloat = 1.0
    @State private var rotation: Angle = .zero
    @State private var lastRotation: Angle = .zero
    @State private var isGestureActive: Bool = false
    @State private var cornerDragScale: CGFloat = 1.0
    @State private var cornerDragOffset: CGSize = .zero

    private let handleSize: CGFloat = 14
    private let handleHitArea: CGFloat = 30

    var body: some View {
        let baseSize = CGSize(
            width: item.size.width * item.scale * currentScale,
            height: item.size.height * item.scale * currentScale
        )
        let displaySize = CGSize(
            width: baseSize.width * cornerDragScale,
            height: baseSize.height * cornerDragScale
        )
        let isSelected = selectedItemID == item.id

        ZStack {
            item.image
                .resizable()
                .scaledToFit()
        }
        .frame(width: displaySize.width, height: displaySize.height)
        .background(
            Group {
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
            }
        )
        .overlay(
            Rectangle()
                .stroke(Color.white, lineWidth: 2)
                .opacity(isSelected && !isGestureActive ? 1 : 0)
        )
        .overlay(
            Group {
                if isSelected && !isGestureActive {
                    cornerHandlesOverlay(displaySize: displaySize, baseSize: baseSize)
                }
            }
        )
        .rotationEffect(rotation)
        .offset(x: dragOffset.width + cornerDragOffset.width,
                y: dragOffset.height + cornerDragOffset.height)
        .onTapGesture {
            if selectedItemID == item.id {
                selectedItemID = nil
            } else {
                selectedItemID = item.id
            }
        }
        .gesture(
            DragGesture(minimumDistance: 10)
                .onChanged { value in
                    // On first touch, validate if we're touching an opaque pixel
                    if !isGestureActive {
                        if let uiImage = item.uiImage {
                            let result = isTouchingOpaquePixel(
                                at: value.startLocation,
                                imageSize: displaySize,
                                image: uiImage
                            )
                            if result {
                                isGestureActive = true
                                isAnyItemDragging = true
                                selectedItemID = item.id
                            } else {
                                return
                            }
                        } else {
                            isGestureActive = true
                            isAnyItemDragging = true
                            selectedItemID = item.id
                        }
                    }

                    if isGestureActive {
                        dragOffset = value.translation
                    }
                }
                .onEnded { value in
                    if isGestureActive {
                        let newPosition = CGPoint(
                            x: item.position.x + value.translation.width,
                            y: item.position.y + value.translation.height
                        )
                        item.position = newPosition
                        dragOffset = .zero
                        isGestureActive = false
                        isAnyItemDragging = false
                    }
                }
        )
        .simultaneousGesture(
            MagnificationGesture()
                .onChanged { value in
                    currentScale = value
                }
                .onEnded { value in
                    item.scale *= value
                    currentScale = 1.0
                }
        )
        .simultaneousGesture(
            RotationGesture()
                .onChanged { value in
                    rotation = lastRotation + value
                }
                .onEnded { value in
                    lastRotation += value
                }
        )
    }

    // MARK: - Corner Handles

    @ViewBuilder
    private func cornerHandlesOverlay(displaySize: CGSize, baseSize: CGSize) -> some View {
        ZStack {
            cornerHandle(corner: .topLeft,     displaySize: displaySize, baseSize: baseSize)
            cornerHandle(corner: .topRight,    displaySize: displaySize, baseSize: baseSize)
            cornerHandle(corner: .bottomLeft,  displaySize: displaySize, baseSize: baseSize)
            cornerHandle(corner: .bottomRight, displaySize: displaySize, baseSize: baseSize)
        }
    }

    private enum Corner {
        case topLeft, topRight, bottomLeft, bottomRight

        /// Unit direction of this corner from center: +1 = right/down, -1 = left/up
        var xDir: CGFloat { (self == .topRight || self == .bottomRight) ? 1 : -1 }
        var yDir: CGFloat { (self == .bottomLeft || self == .bottomRight) ? 1 : -1 }
    }

    @ViewBuilder
    private func cornerHandle(corner: Corner, displaySize: CGSize, baseSize: CGSize) -> some View {
        Circle()
            .fill(Color.white)
            .frame(width: handleSize, height: handleSize)
            .shadow(color: .black.opacity(0.4), radius: 2, x: 0, y: 1)
            // Expand the hit area without changing visual size
            .contentShape(Rectangle().size(CGSize(width: handleHitArea, height: handleHitArea)))
            .frame(width: handleHitArea, height: handleHitArea)
            .position(x: displaySize.width / 2 + corner.xDir * displaySize.width / 2,
                      y: displaySize.height / 2 + corner.yDir * displaySize.height / 2)
            .gesture(
                DragGesture(minimumDistance: 2, coordinateSpace: .global)
                    .onChanged { value in
                        // Use baseSize (stable for the whole drag) as the reference.
                        let baseDiag = sqrt(baseSize.width * baseSize.width + baseSize.height * baseSize.height)
                        guard baseDiag > 0 else { return }

                        // value.translation is in global (screen) space.
                        // Rotate it into the item's local space so the projection is correct.
                        let angle = rotation.radians
                        let cosA = cos(angle)
                        let sinA = sin(angle)
                        let tx = value.translation.width
                        let ty = value.translation.height
                        let localDx = tx * cosA + ty * sinA
                        let localDy = -tx * sinA + ty * cosA

                        // Project onto this corner's outward diagonal in local space.
                        let signedDx = localDx * corner.xDir
                        let signedDy = localDy * corner.yDir
                        let normalX = baseSize.width  / baseDiag
                        let normalY = baseSize.height / baseDiag
                        let delta = signedDx * normalX + signedDy * normalY

                        let newDiag = max(40, baseDiag + delta)
                        let scale = newDiag / baseDiag
                        cornerDragScale = scale

                        // The center shift in local space (half the size growth toward dragged corner).
                        let localOffsetX = (baseSize.width  * scale - baseSize.width)  * corner.xDir / 2
                        let localOffsetY = (baseSize.height * scale - baseSize.height) * corner.yDir / 2

                        // Rotate the local offset back into parent (canvas) space.
                        cornerDragOffset = CGSize(
                            width:  localOffsetX * cosA - localOffsetY * sinA,
                            height: localOffsetX * sinA + localOffsetY * cosA
                        )
                    }
                    .onEnded { _ in
                        item.scale *= cornerDragScale
                        item.position = CGPoint(
                            x: item.position.x + cornerDragOffset.width,
                            y: item.position.y + cornerDragOffset.height
                        )
                        cornerDragScale = 1.0
                        cornerDragOffset = .zero
                    }
            )
    }

    /// Checks if a touch location is on an opaque pixel of the image
    private func isTouchingOpaquePixel(at location: CGPoint, imageSize: CGSize, image: UIImage) -> Bool {
        let touchX = location.x
        let touchY = location.y

        // Check bounds
        guard touchX >= 0, touchX <= imageSize.width,
              touchY >= 0, touchY <= imageSize.height else {
            return false
        }

        // Convert to normalized coordinates (0-1)
        let normalizedX = touchX / imageSize.width
        let normalizedY = touchY / imageSize.height

        return image.isOpaqueAt(normalizedPoint: CGPoint(x: normalizedX, y: normalizedY))
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
