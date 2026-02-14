import SwiftUI

/// View for exporting and sharing the collage
struct ExportView: View {
    let image: Image?
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.opacity(0.9).ignoresSafeArea()
                if let image {
                    image
                        .resizable()
                        .scaledToFit()
                        .padding()
                } else {
                    ProgressView()
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    if let rendered = renderedUIImage() {
                        ShareLink(
                            item: Image(uiImage: rendered),
                            preview: SharePreview("Collage", image: Image(uiImage: rendered))
                        ) {
                            Text("Share")
                        }
                    }
                }
            }
        }
    }

    private func renderedUIImage() -> UIImage? {
        guard let image else { return nil }
        let renderer = ImageRenderer(content: image.resizable().scaledToFit())
        renderer.scale = Constants.Rendering.screenScale
        return renderer.uiImage
    }
}
