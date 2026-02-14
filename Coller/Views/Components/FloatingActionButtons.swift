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
                .padding()
        }
        .buttonStyle(.glass)
        .clipShape(.circle)
        .padding(Constants.UI.fabClusterPadding)
    }
}
