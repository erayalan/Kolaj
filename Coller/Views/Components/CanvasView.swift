import SwiftUI

/// Canvas view displaying all collage items
struct CanvasView: View {
    @Binding var items: [CollageItem]
    @Binding var selectedItemID: UUID?
    @Binding var isAnyItemDragging: Bool
    var backgroundColor: Color = Color(.systemBackground)
    @Environment(\.colorScheme) private var colorScheme

    /// Returns black for light backgrounds, white for dark backgrounds.
    private var quoteColor: Color {
        let traitCollection = UITraitCollection(userInterfaceStyle: colorScheme == .dark ? .dark : .light)
        let uiColor = UIColor(backgroundColor).resolvedColor(with: traitCollection)
        var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
        uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        let luminance = 0.2126 * red + 0.7152 * green + 0.0722 * blue
        return luminance > 0.5 ? .black : .white
    }

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                backgroundColor
                    .contentShape(Rectangle())
                    .onTapGesture {
                        selectedItemID = nil
                    }
                if items.isEmpty {
                    VStack(spacing: 24) {
                        Text("\"Collage is the alchemy of the visual image.\" - Max Ernst")
                            .font(.system(size: 20, weight: .bold, design: .serif))
                            .italic()
                        Text("Add your photos on the canvas to start your alchemy.")
                            .font(.system(size: 16, weight: .light,))
                    }
                    .multilineTextAlignment(.center)
                    .foregroundStyle(quoteColor.opacity(0.5))
                    .padding(.horizontal, 40)
                    .allowsHitTesting(false)
                }
                ForEach($items) { $item in
                    DraggableResizableItem(
                        item: $item,
                        selectedItemID: $selectedItemID,
                        isAnyItemDragging: $isAnyItemDragging,
                        canvasBackgroundColor: backgroundColor
                    )
                    .position(item.position)
                }
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
        }
    }
}
