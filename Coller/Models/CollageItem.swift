import Foundation
import SwiftUI

/// Model representing a placed image on the canvas
struct CollageItem: Identifiable, Equatable {
    let id: UUID
    var image: Image
    var size: CGSize
    var position: CGPoint
    var scale: CGFloat = 1.0
    var rotation: Angle = .zero
    var cutoutBorderColor: CutoutBorderColor = .none
    var customBorderColor: Color = .white

    /// Optional UIImage reference for export optimization
    /// Allows exporting without re-rendering from SwiftUI Image
    var uiImage: UIImage?

    init(
        id: UUID = UUID(),
        image: Image,
        size: CGSize,
        position: CGPoint,
        scale: CGFloat = 1.0,
        rotation: Angle = .zero,
        cutoutBorderColor: CutoutBorderColor = .none,
        customBorderColor: Color = .white,
        uiImage: UIImage? = nil
    ) {
        self.id = id
        self.image = image
        self.size = size
        self.position = position
        self.scale = scale
        self.rotation = rotation
        self.cutoutBorderColor = cutoutBorderColor
        self.customBorderColor = customBorderColor
        self.uiImage = uiImage
    }

    static func == (lhs: CollageItem, rhs: CollageItem) -> Bool {
        lhs.id == rhs.id &&
        lhs.size == rhs.size &&
        lhs.position == rhs.position &&
        lhs.scale == rhs.scale &&
        lhs.rotation == rhs.rotation &&
        lhs.cutoutBorderColor == rhs.cutoutBorderColor &&
        lhs.customBorderColor == rhs.customBorderColor
    }
}

enum CanvasBackgroundColor: Int, CaseIterable {
    case primary
    case red
    case yellow
    case green
    case custom

    var color: Color? {
        switch self {
        case .primary: return Color(.systemBackground)
        case .red:     return Color(red: 1.0, green: 0.07, blue: 0.07)
        case .yellow:  return Color(red: 1.0, green: 0.95, blue: 0.0)
        case .green:   return Color(red: 0.07, green: 1.0, blue: 0.07)
        case .custom:  return nil
        }
    }

    func next() -> CanvasBackgroundColor {
        let all = Self.allCases
        let nextIndex = (rawValue + 1) % all.count
        return all[nextIndex]
    }
}

enum CutoutBorderColor: Int, CaseIterable {
    case primary
    case red
    case yellow
    case green
    case black
    case custom
    case none

    var color: Color? {
        switch self {
        case .primary:
            return .primary
        case .red:
            return Color(red: 1.0, green: 0.07, blue: 0.07)
        case .yellow:
            return Color(red: 1.0, green: 0.95, blue: 0.0)
        case .green:
            return Color(red: 0.07, green: 1.0, blue: 0.07)
        case .black:
            return .black
        case .custom:
            return nil  // resolved at the call site using customBorderColor
        case .none:
            return nil
        }
    }

    func next() -> CutoutBorderColor {
        let all = Self.allCases
        let nextIndex = (rawValue + 1) % all.count
        return all[nextIndex]
    }
}
