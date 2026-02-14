import Foundation
import SwiftUI

/// Unified application state for the Coller app
@Observable
final class AppState {
    /// All items currently on the canvas
    var items: [CollageItem] = []

    /// Current canvas size (updated by GeometryReader)
    var canvasSize: CGSize = .zero

    /// Whether the export sheet is currently presented
    var isExporting: Bool = false

    /// The rendered image ready for export
    var exportImage: Image?

    /// Current error to display to the user
    var error: AppError?

    /// Whether image processing is currently in progress
    var isProcessing: Bool = false

    /// Currently selected item on the canvas, if any
    var selectedItemID: UUID?

    init() {}
}

/// User-facing error types with localized messages
enum AppError: Error, Identifiable {
    case imageLoadFailed(details: String? = nil)
    case backgroundRemovalFailed
    case exportFailed
    case processingFailed

    var id: String {
        switch self {
        case .imageLoadFailed: return "imageLoadFailed"
        case .backgroundRemovalFailed: return "backgroundRemovalFailed"
        case .exportFailed: return "exportFailed"
        case .processingFailed: return "processingFailed"
        }
    }

    var title: String {
        switch self {
        case .imageLoadFailed: return "Image Load Failed"
        case .backgroundRemovalFailed: return "Background Removal Failed"
        case .exportFailed: return "Export Failed"
        case .processingFailed: return "Processing Failed"
        }
    }

    var message: String {
        switch self {
        case .imageLoadFailed(let details):
            if let details = details {
                return "Failed to load image: \(details)"
            }
            return Constants.ErrorMessages.imageLoadFailed
        case .backgroundRemovalFailed:
            return Constants.ErrorMessages.backgroundRemovalFailed
        case .exportFailed:
            return Constants.ErrorMessages.exportFailed
        case .processingFailed:
            return Constants.ErrorMessages.processingFailed
        }
    }
}
