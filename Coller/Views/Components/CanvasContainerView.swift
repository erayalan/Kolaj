import SwiftUI

/// Container view for the canvas that tracks size changes
struct CanvasContainerView: View {
    @Binding var items: [CollageItem]
    @Binding var selectedItemID: UUID?
    let onSizeChange: (CGSize) -> Void

    var body: some View {
        GeometryReader { proxy in
            CanvasView(items: $items, selectedItemID: $selectedItemID)
                .background(Color(.systemBackground))
                .onAppear {
                    onSizeChange(proxy.size)
                }
                .onChange(of: proxy.size) { _, newSize in
                    onSizeChange(newSize)
                }
        }
        .ignoresSafeArea()
    }
}
