import SwiftUI
import PhotosUI

struct ContentView: View {
    @State private var viewModel = CollageViewModel()
    @State private var pickerItems: [PhotosPickerItem] = []
    @State private var isAnyItemDragging: Bool = false
    private var showLayerActions: Bool { viewModel.state.selectedItemID != nil && !isAnyItemDragging }

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            // Canvas
            CanvasContainerView(
                items: $viewModel.state.items,
                selectedItemID: $viewModel.state.selectedItemID,
                isAnyItemDragging: $isAnyItemDragging,
                onSizeChange: { size in
                    viewModel.updateCanvasSize(size)
                }
            )

            // Add photos button (bottom right), hidden when layer actions are visible
            if !showLayerActions {
                FloatingActionButtons(pickerItems: $pickerItems)
                    .padding(Constants.UI.fabClusterPadding)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
            }

            // Layer controls, shown when layer actions are visible
            if showLayerActions && viewModel.state.selectedItemID != nil {
                // Top left: layer order buttons (two standalone buttons, no grouping)
                HStack(spacing: Constants.UI.fabSpacing) {
                    // Move forward: tap = one layer up, long press = to front
                    Button(action: {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        viewModel.moveSelectedItemForward()
                    }) {
                        Image(systemName: "square.2.layers.3d.top.filled")
                            .font(.system(size: Constants.UI.plusIconSize, weight: .bold))
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
                }
                .padding(Constants.UI.fabClusterPadding)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)

                // Bottom left: border button
                Button(action: viewModel.cycleSelectedItemBorderColor) {
                    Image(systemName: "square")
                        .font(.system(size: Constants.UI.plusIconSize, weight: .bold))
                        .padding(.all, 8)
                }
                .buttonStyle(.glass)
                .clipShape(.circle)
                .padding(Constants.UI.fabClusterPadding)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)

                // Top right: delete button
                Button(action: viewModel.deleteSelectedItem) {
                    Image(systemName: "trash")
                        .font(.system(size: Constants.UI.plusIconSize, weight: .bold))
                        .padding(.all, 8)
                }
                .buttonStyle(.glass)
                .clipShape(.circle)
                .padding(Constants.UI.fabClusterPadding)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
            }

            // Share button (top right), hidden when layer actions are visible
            if !showLayerActions, let rendered = viewModel.renderCanvasImage() {
                ShareLink(
                    item: Image(uiImage: rendered),
                    preview: SharePreview("Collage", image: Image(uiImage: rendered))
                ) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: Constants.UI.plusIconSize, weight: .bold))
                        .padding(.all, 8)
                }
                .buttonStyle(.glass)
                .clipShape(.circle)
                .padding(Constants.UI.fabClusterPadding)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
            }

            // Loading overlay
            LoadingOverlay(isLoading: viewModel.state.isProcessing)
        }
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

#Preview {
    ContentView()
}
