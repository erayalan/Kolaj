import SwiftUI

/// Loading overlay displayed during image processing
struct LoadingOverlay: View {
    let isLoading: Bool

    var body: some View {
        if isLoading {
            ZStack {
                Color.black.opacity(0.4)
                    .ignoresSafeArea()

                VStack(spacing: 16) {
                    ProgressView()
                        .scaleEffect(1.5)

                    Text("Cutting out backgrounds...")
                        .font(.headline)
                        .multilineTextAlignment(.center)
                }
                .padding(.vertical, 24)
                .padding(.horizontal, 24)
                .frame(width: 270)
                .glassEffect(in: .rect(cornerRadius: 32.0))
                //.shadow(color: Color.black.opacity(0.3), radius: 20, x: 0, y: 10)
            }
        }
    }
}
