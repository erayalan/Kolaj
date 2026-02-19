import Foundation
import CoreGraphics
import UIKit

/// Centralized constants for the Coller app
enum Constants {

    /// Layout and sizing constants
    enum Layout {
        /// Fraction of canvas height used for initial image sizing
        static let initialImageHeightFraction: CGFloat = 1 / 3

        /// Minimum image height to ensure visibility
        static let minImageHeight: CGFloat = 40

        /// Default item size for auto-placement grid (unused currently)
        static let autoPlaceDefaultSize: CGFloat = 60

        /// Padding between auto-placed items (unused currently)
        static let autoPlacePadding: CGFloat = 8

        /// Maximum number of photos that can be selected at once
        static let maxPhotoSelection: Int = 20
    }

    /// UI spacing and sizing constants
    enum UI {
        /// Spacing between floating action buttons
        static let fabSpacing: CGFloat = 12

        /// Horizontal padding for export button
        static let exportButtonPaddingH: CGFloat = 16

        /// Vertical padding for export button
        static let exportButtonPaddingV: CGFloat = 12

        /// Size of the plus icon (layer control buttons)
        static let plusIconSize: CGFloat = 16

        /// Size of the main action button icons (add photo, export)
        static let mainActionIconSize: CGFloat = 16

        /// Padding inside the plus button circle
        static let plusButtonPadding: CGFloat = 18

        /// Stroke width for plus button border
        static let plusButtonStrokeWidth: CGFloat = 1

        /// Shadow radius for plus button
        static let plusButtonShadowRadius: CGFloat = 8

        /// Additional padding around plus button
        static let plusButtonExtraPadding: CGFloat = 6

        /// Padding around the floating action button cluster
        static let fabClusterPadding: CGFloat = 16

        /// Width of the cutout border in screen points
        static let cutoutBorderWidth: CGFloat = 20
    }

    /// Animation and rendering constants
    enum Rendering {
        /// Default screen scale multiplier for exports
        static var screenScale: CGFloat { UIScreen.main.scale }
    }

    /// Error messages for user-facing alerts
    enum ErrorMessages {
        static let imageLoadFailed = "Failed to load one or more images. Please try again."
        static let backgroundRemovalFailed = "Background removal failed. Using original image."
        static let exportFailed = "Failed to export collage. Please try again."
        static let processingFailed = "Failed to process image. Please try again."
    }
}
