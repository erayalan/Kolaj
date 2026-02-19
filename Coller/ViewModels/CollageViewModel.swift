import Foundation
import SwiftUI
import PhotosUI
import UIKit

/// Main view model coordinating the collage creation workflow
@MainActor
@Observable
final class CollageViewModel {

    /// Application state
    var state = AppState()

    // MARK: - Services (injected with defaults)
    private let imageProcessingService: ImageProcessingProtocol
    private let backgroundRemovalService: BackgroundRemovalProtocol
    private let canvasExportService: CanvasExportProtocol
    private let boundaryFeedback = UIImpactFeedbackGenerator(style: .light)

    // MARK: - Initialization

    init(
        imageProcessingService: ImageProcessingProtocol? = nil,
        backgroundRemovalService: BackgroundRemovalProtocol? = nil,
        canvasExportService: CanvasExportProtocol? = nil
    ) {
        self.imageProcessingService = imageProcessingService ?? ImageProcessingService.shared
        self.backgroundRemovalService = backgroundRemovalService ?? BackgroundRemovalService.shared
        self.canvasExportService = canvasExportService ?? CanvasExportService.shared
    }

    // MARK: - Public API

    /// Loads and processes picked photo items
    /// - Parameter items: PhotosPickerItems to process
    func loadPickedItems(_ items: [PhotosPickerItem]) async {
        guard !items.isEmpty else { return }

        // Set processing state
        state.isProcessing = true
        state.error = nil

        // Process items in background
        let newItems = await imageProcessingService.processPickedItems(
            items,
            canvasSize: state.canvasSize,
            backgroundRemovalService: backgroundRemovalService
        )

        // Update state on main thread
        state.items.append(contentsOf: newItems)
        state.isProcessing = false
    }

    /// Renders the current canvas as a UIImage for saving or sharing
    func renderCanvasImage(colorScheme: ColorScheme) -> UIImage? {
        guard !state.items.isEmpty else { return nil }
        let resolvedColor: Color
        if state.canvasBackgroundColor == .custom {
            resolvedColor = state.canvasCustomBackgroundColor
        } else if state.canvasBackgroundColor == .primary {
            resolvedColor = colorScheme == .dark ? .black : .white
        } else {
            resolvedColor = state.canvasBackgroundColor.color ?? .white
        }
        return canvasExportService.renderCanvas(items: state.items, size: state.canvasSize, backgroundColor: resolvedColor, colorScheme: colorScheme)
    }

    /// Updates the canvas size
    /// - Parameter size: New canvas size
    func updateCanvasSize(_ size: CGSize) {
        state.canvasSize = size
    }

    /// Clears the current error
    func clearError() {
        state.error = nil
    }

    /// Deletes the currently selected item, if any
    func deleteSelectedItem() {
        guard let selectedID = state.selectedItemID else { return }
        state.items.removeAll { $0.id == selectedID }
        state.selectedItemID = nil
    }

    /// Moves the selected item one layer forward (toward front)
    func moveSelectedItemForward() {
        guard let selectedID = state.selectedItemID,
              let index = state.items.firstIndex(where: { $0.id == selectedID }) else { return }
        guard index < state.items.count - 1 else {
            boundaryFeedback.impactOccurred()
            return
        }
        state.items.swapAt(index, index + 1)
    }

    /// Moves the selected item one layer backward (toward back)
    func moveSelectedItemBackward() {
        guard let selectedID = state.selectedItemID,
              let index = state.items.firstIndex(where: { $0.id == selectedID }) else { return }
        guard index > 0 else {
            boundaryFeedback.impactOccurred()
            return
        }
        state.items.swapAt(index, index - 1)
    }

    /// Moves the selected item to the front (topmost layer)
    func moveSelectedItemToFront() {
        guard let selectedID = state.selectedItemID,
              let index = state.items.firstIndex(where: { $0.id == selectedID }) else { return }
        guard index < state.items.count - 1 else {
            boundaryFeedback.impactOccurred()
            return
        }
        let item = state.items.remove(at: index)
        state.items.append(item)
    }

    /// Moves the selected item to the back (bottommost layer)
    func moveSelectedItemToBack() {
        guard let selectedID = state.selectedItemID,
              let index = state.items.firstIndex(where: { $0.id == selectedID }) else { return }
        guard index > 0 else {
            boundaryFeedback.impactOccurred()
            return
        }
        let item = state.items.remove(at: index)
        state.items.insert(item, at: 0)
    }

    /// Cycles the cutout border color for the selected item.
    /// Returns true when it cycles to .custom, so the caller can open a color picker.
    @discardableResult
    func cycleSelectedItemBorderColor() -> Bool {
        guard let selectedID = state.selectedItemID,
              let index = state.items.firstIndex(where: { $0.id == selectedID }) else { return false }
        let next = state.items[index].cutoutBorderColor.next()
        state.items[index].cutoutBorderColor = next
        return next == .custom
    }

    /// Cycles the canvas background color to the next preset
    func cycleCanvasBackgroundColor() {
        state.canvasBackgroundColor = state.canvasBackgroundColor.next()
    }
}
