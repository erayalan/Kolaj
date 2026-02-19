import Foundation
import SwiftUI

/// Protocol for canvas export services
protocol CanvasExportProtocol {
    func renderCanvas(items: [CollageItem], size: CGSize, backgroundColor: Color, colorScheme: ColorScheme) -> UIImage?
}

/// Service for exporting canvas to image
final class CanvasExportService: CanvasExportProtocol {

    /// Shared singleton instance
    static let shared = CanvasExportService()

    private init() {}

    /// Renders the canvas to a UIImage
    /// - Parameters:
    ///   - items: Items to render on the canvas
    ///   - size: Size of the canvas to render
    ///   - backgroundColor: Background color of the canvas
    ///   - colorScheme: The current color scheme, applied to the renderer environment
    /// - Returns: Rendered UIImage, or nil if rendering fails
    func renderCanvas(items: [CollageItem], size: CGSize, backgroundColor: Color, colorScheme: ColorScheme) -> UIImage? {
        // Create a binding wrapper for rendering
        let itemsBinding = Binding<[CollageItem]>(
            get: { items },
            set: { _ in }
        )

        // Use ImageRenderer to render the CanvasView
        let renderer = ImageRenderer(
            content: CanvasView(items: itemsBinding, selectedItemID: .constant(nil), isAnyItemDragging: .constant(false), backgroundColor: backgroundColor)
                .frame(width: size.width, height: size.height)
                .environment(\.colorScheme, colorScheme)
        )
        renderer.scale = Constants.Rendering.screenScale

        return renderer.uiImage
    }
}

