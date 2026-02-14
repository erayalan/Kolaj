import SwiftUI
import PhotosUI

/// Floating action button for adding photos
struct FloatingActionButtons: View {
    @Binding var pickerItems: [PhotosPickerItem]

    var body: some View {
        PhotosPicker(
            selection: $pickerItems,
            maxSelectionCount: Constants.Layout.maxPhotoSelection,
            matching: .images
        ) {
            Image(systemName: "plus")
                .font(.system(size: Constants.UI.plusIconSize, weight: .bold))
                .foregroundStyle(.primary)
                .padding()
        }
        .buttonStyle(.glass)
        .padding(Constants.UI.fabClusterPadding)
    }
}
