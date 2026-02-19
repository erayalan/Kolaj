import SwiftUI
import PhotosUI

struct ContentView: View {
    @State private var viewModel = CollageViewModel()
    @State private var pickerItems: [PhotosPickerItem] = []
    @State private var isAnyItemDragging: Bool = false
    @Environment(\.colorScheme) private var colorScheme

    private var showLayerActions: Bool { viewModel.state.selectedItemID != nil && !isAnyItemDragging }

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            // Canvas
            CanvasContainerView(
                items: $viewModel.state.items,
                selectedItemID: $viewModel.state.selectedItemID,
                isAnyItemDragging: $isAnyItemDragging,
                canvasBackgroundColor: $viewModel.state.canvasBackgroundColor,
                canvasCustomBackgroundColor: $viewModel.state.canvasCustomBackgroundColor,
                onSizeChange: { size in
                    viewModel.updateCanvasSize(size)
                }
            )

            // Add photos button (bottom right), hidden when dragging
            if !isAnyItemDragging {
                FloatingActionButtons(pickerItems: $pickerItems)
                    .safeAreaPadding(Constants.UI.fabClusterPadding)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)

                // Background color button (bottom left)
                Button(action: {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    viewModel.state.canvasBackgroundColor = .custom
                    presentColorPicker(selection: $viewModel.state.canvasCustomBackgroundColor)
                }) {
                    Image(systemName: "paint.bucket.classic")
                        .font(.system(size: Constants.UI.plusIconSize, weight: .bold))
                        .frame(width: Constants.UI.plusIconSize, height: Constants.UI.plusIconSize)
                        .padding(.all, 8)
                }
                .buttonStyle(.glass)
                .clipShape(.circle)
                .safeAreaPadding(Constants.UI.fabClusterPadding)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
            }

            // Layer controls, shown when layer actions are visible
            if showLayerActions && viewModel.state.selectedItemID != nil {
                VStack(spacing: 12) {
                    // Move forward: tap = one layer up, long press = to front
                    Button(action: {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        viewModel.moveSelectedItemForward()
                    }) {
                        Image(systemName: "square.2.layers.3d.top.filled")
                            .font(.system(size: Constants.UI.plusIconSize, weight: .bold))
                            .frame(width: Constants.UI.plusIconSize, height: Constants.UI.plusIconSize)
                            .padding(.all, 8)
                    }
                    .buttonStyle(.glass)
                    .clipShape(.circle)
                    .simultaneousGesture(
                        LongPressGesture(minimumDuration: 0.5)
                            .onEnded { _ in
                                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                                viewModel.moveSelectedItemToFront()
                            }
                    )

                    // Move backward: tap = one layer down, long press = to back
                    Button(action: {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        viewModel.moveSelectedItemBackward()
                    }) {
                        Image(systemName: "square.2.layers.3d.bottom.filled")
                            .font(.system(size: Constants.UI.plusIconSize, weight: .bold))
                            .frame(width: Constants.UI.plusIconSize, height: Constants.UI.plusIconSize)
                            .padding(.all, 8)
                    }
                    .buttonStyle(.glass)
                    .clipShape(.circle)
                    .simultaneousGesture(
                        LongPressGesture(minimumDuration: 0.5)
                            .onEnded { _ in
                                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                                viewModel.moveSelectedItemToBack()
                            }
                    )

                    // Border color button: removes border if active, opens picker if none
                    let selectedIndex = viewModel.state.selectedItemID.flatMap { id in
                        viewModel.state.items.firstIndex(where: { $0.id == id })
                    }
                    let hasBorder = selectedIndex.map { viewModel.state.items[$0].cutoutBorderColor != .none } ?? false
                    Button(action: {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        if hasBorder {
                            if let index = selectedIndex {
                                viewModel.state.items[index].cutoutBorderColor = .none
                            }
                        } else {
                            if let index = selectedIndex {
                                viewModel.state.items[index].cutoutBorderColor = .custom
                                presentColorPicker(selection: $viewModel.state.items[index].customBorderColor)
                            }
                        }
                    }) {
                        Image(systemName: hasBorder ? "square.slash" : "square")
                            .font(.system(size: Constants.UI.plusIconSize, weight: .bold))
                            .frame(width: Constants.UI.plusIconSize, height: Constants.UI.plusIconSize)
                            .padding(.all, 8)
                    }
                    .buttonStyle(.glass)
                    .clipShape(.circle)

                    // Delete button at the bottom
                    Button(action: viewModel.deleteSelectedItem) {
                        Image(systemName: "trash")
                            .font(.system(size: Constants.UI.plusIconSize, weight: .bold))
                            .frame(width: Constants.UI.plusIconSize, height: Constants.UI.plusIconSize)
                            .padding(.all, 8)
                    }
                    .buttonStyle(.glass)
                    .clipShape(.circle)
                }
                .safeAreaPadding(Constants.UI.fabClusterPadding)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            }

            // Share button (top right), hidden when dragging
            if !isAnyItemDragging, let rendered = viewModel.renderCanvasImage(colorScheme: colorScheme) {
                ShareLink(
                    item: Image(uiImage: rendered),
                    preview: SharePreview("Collage", image: Image(uiImage: rendered))
                ) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: Constants.UI.plusIconSize, weight: .bold))
                        .frame(width: Constants.UI.plusIconSize, height: Constants.UI.plusIconSize)
                        .padding(.all, 8)
                }
                .buttonStyle(.glass)
                .clipShape(.circle)
                .safeAreaPadding(Constants.UI.fabClusterPadding)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
            }

            // Loading overlay
            LoadingOverlay(isLoading: viewModel.state.isProcessing)
        }
        .statusBarHidden()
        .errorAlert(error: $viewModel.state.error) {
            viewModel.clearError()
        }
        .onChange(of: pickerItems) { _, newItems in
            Task {
                await viewModel.loadPickedItems(newItems)
                pickerItems = []
            }
        }
    }


}

/// Presents UIColorPickerViewController imperatively from the root view controller so that
/// the system palette grid button can push sub-controllers without crashing.
func presentColorPicker(selection: Binding<Color>, supportsAlpha: Bool = true) {
    guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
          let root = scene.windows.first(where: \.isKeyWindow)?.rootViewController else { return }
    // Walk up to the topmost presented controller
    var top = root
    while let presented = top.presentedViewController { top = presented }

    let picker = UIColorPickerViewController()
    picker.selectedColor = UIColor(selection.wrappedValue)
    picker.supportsAlpha = supportsAlpha
    picker.delegate = ColorPickerDelegate.shared.configure(binding: selection)
    top.present(picker, animated: true)
}

/// Singleton delegate that bridges UIColorPickerViewController callbacks back to a SwiftUI Binding.
private final class ColorPickerDelegate: NSObject, UIColorPickerViewControllerDelegate {
    static let shared = ColorPickerDelegate()
    private var binding: Binding<Color>?

    func configure(binding: Binding<Color>) -> Self {
        self.binding = binding
        return self
    }

    func colorPickerViewController(_ viewController: UIColorPickerViewController, didSelect color: UIColor, continuously: Bool) {
        binding?.wrappedValue = Color(color)
    }
}

#Preview {
    ContentView()
}
