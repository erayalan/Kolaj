import SwiftUI

/// Container view for the canvas that tracks size changes
struct CanvasContainerView: View {
    @Binding var items: [CollageItem]
    @Binding var selectedItemID: UUID?
    @Binding var isAnyItemDragging: Bool
    @Binding var canvasBackgroundColor: CanvasBackgroundColor
    @Binding var canvasCustomBackgroundColor: Color
    let onSizeChange: (CGSize) -> Void

    var body: some View {
        GeometryReader { proxy in
            CanvasView(
                items: $items,
                selectedItemID: $selectedItemID,
                isAnyItemDragging: $isAnyItemDragging,
                backgroundColor: resolvedBackgroundColor
            )
            .onAppear {
                onSizeChange(proxy.size)
            }
            .onChange(of: proxy.size) { _, newSize in
                onSizeChange(newSize)
            }
        }
        .ignoresSafeArea()
    }

    private var resolvedBackgroundColor: Color {
        if canvasBackgroundColor == .custom {
            return canvasCustomBackgroundColor
        }
        return canvasBackgroundColor.color ?? .primary
    }
}
