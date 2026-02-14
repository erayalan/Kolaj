import SwiftUI
import PhotosUI

struct ContentView: View {
    @State private var viewModel = CollageViewModel()
    @State private var pickerItems: [PhotosPickerItem] = []
    private var hasCanvasItems: Bool { !viewModel.state.items.isEmpty }

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            // Canvas
            CanvasContainerView(
                items: $viewModel.state.items,
                selectedItemID: $viewModel.state.selectedItemID
            ) { size in
                viewModel.updateCanvasSize(size)
            }

            if !hasCanvasItems {
                Text("Tap + to add photos (backgrounds removed) to your canvas.")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Constants.UI.fabClusterPadding)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            }

            // Floating action buttons
            FloatingActionButtons(
                pickerItems: $pickerItems
            )

            if viewModel.state.selectedItemID != nil {
                VStack(spacing: Constants.UI.fabSpacing) {
                    Button(action: viewModel.moveSelectedItemForward) {
                        Image(systemName: "arrow.up")
                            .font(.system(size: Constants.UI.plusIconSize, weight: .bold))
                            .foregroundStyle(.primary)
                            .padding()
                    }
                    .buttonStyle(.glass)

                    Button(action: viewModel.moveSelectedItemBackward) {
                        Image(systemName: "arrow.down")
                            .font(.system(size: Constants.UI.plusIconSize, weight: .bold))
                            .foregroundStyle(.primary)
                            .padding()
                    }
                    .buttonStyle(.glass)

                    Button(action: viewModel.cycleSelectedItemBorderColor) {
                        Image(systemName: "square")
                            .font(.system(size: Constants.UI.plusIconSize, weight: .bold))
                            .foregroundStyle(.primary)
                            .padding()
                    }
                    .buttonStyle(.glass)

                    Button(action: viewModel.deleteSelectedItem) {
                        Image(systemName: "trash")
                            .font(.system(size: Constants.UI.plusIconSize, weight: .bold))
                            .foregroundStyle(.primary)
                            .padding()
                    }
                    .buttonStyle(.glass)
                }
                .padding(Constants.UI.fabClusterPadding)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
            }

            Button(action: viewModel.exportCanvas) {
                Image(systemName: "photo.circle")
                    .font(.system(size: Constants.UI.plusIconSize, weight: .bold))
                    .foregroundStyle(.primary)
                    .padding()
            }
            .buttonStyle(.glass)
            .disabled(!hasCanvasItems)
            .opacity(hasCanvasItems ? 1 : 0.4)
            .padding(Constants.UI.fabClusterPadding)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)

            // Loading overlay
            LoadingOverlay(isLoading: viewModel.state.isProcessing)
        }
        .sheet(isPresented: $viewModel.state.isExporting) {
            ExportView(image: viewModel.state.exportImage)
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
