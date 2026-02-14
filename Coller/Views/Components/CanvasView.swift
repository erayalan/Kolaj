import SwiftUI

/// Canvas view displaying all collage items
struct CanvasView: View {
    @Binding var items: [CollageItem]
    @Binding var selectedItemID: UUID?

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                Color.clear
                    .contentShape(Rectangle())
                    .onTapGesture {
                        selectedItemID = nil
                    }
                ForEach($items) { $item in
                    DraggableResizableItem(item: $item, selectedItemID: $selectedItemID)
                        .position(item.position)
                }
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
        }
    }
}
