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
            Image(systemName: "photo.badge.plus")
                .font(.system(size: Constants.UI.mainActionIconSize, weight: .bold))
                .frame(width: Constants.UI.mainActionIconSize, height: Constants.UI.mainActionIconSize)
                .padding(.all, 8)
        }
        .buttonStyle(.glass)
        .clipShape(.circle)
    }
}
