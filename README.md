# Kolaj - Creative Photo Collages

<p align="center">
  <img src="Coller/Assets.xcassets/AppIcon.appiconset/Kolaj Icon.png" width="120" height="120" alt="Kolaj App Icon">
</p>

<p align="center">
  <strong>Transform your photos into stunning collages with AI-powered background removal</strong>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/platform-iOS%2017.0%2B-blue.svg" alt="Platform: iOS 17.0+">
  <img src="https://img.shields.io/badge/Swift-5.9-orange.svg" alt="Swift 5.9">
  <img src="https://img.shields.io/badge/SwiftUI-5.0-blue.svg" alt="SwiftUI 5.0">
  <img src="https://img.shields.io/badge/license-MIT-green.svg" alt="License: MIT">
</p>

## Overview

Kolaj is a modern iOS collage creation app that combines powerful AI-driven image processing with an intuitive, gesture-based interface. Built entirely with SwiftUI and leveraging Apple's Vision framework, Kolaj enables users to create professional-quality collages with automatic background removal, advanced layer management, and customizable styling.

## Features

### 🤖 AI-Powered Background Removal
- **On-Device Processing**: Uses Vision framework for intelligent foreground segmentation
- **Privacy First**: All image processing happens locally - no cloud uploads
- **Automatic Cropping**: Smart trimming of transparent borders to optimal bounding box
- **Graceful Fallback**: Seamlessly handles processing failures

### 🎨 Intuitive Canvas Controls
- **Multi-Touch Gestures**: Drag, pinch-to-zoom, and rotate with natural touch interactions
- **Smart Touch Detection**: Pixel-level opacity checking (alpha > 25) - only visible parts respond to touch
- **Corner Resize Handles**: Visual handles for precise resizing with maintained aspect ratio
- **Layer Up to 20 Photos**: Create complex, multi-layered compositions

### 📐 Advanced Layer Management
- **Z-Order Controls**:
  - Single tap: Move layer forward/backward one step
  - Long press (0.5s): Move to front/back instantly
- **Visual Selection Indicators**: Color-coded borders show active layer
- **Haptic Feedback**: Tactile response for interactions and boundary conditions
- **Boundary Awareness**: Prevents invalid layer movements with feedback

### 🎭 Creative Customization
- **Custom Cutout Borders**: Add colored borders that follow image contours
- **Color Picker**: Full HSB color picker with alpha channel support
- **Preset Colors**: Quick access to primary, red, yellow, green, and black
- **Canvas Backgrounds**: Customize canvas color with presets or custom colors
- **Adaptive Colors**: Automatic contrast adjustment for light/dark mode

### 📤 Export & Sharing
- **High-Resolution Rendering**: Exports at device native scale (2x/3x)
- **Native ShareSheet**: Share directly to Photos, Messages, Mail, social media
- **Color Scheme Aware**: Respects light/dark mode in exports
- **Format Support**: PNG with transparency support

## Architecture

### Project Structure

```
Kolaj/
├── Coller/
│   ├── CollerApp.swift                 # App entry point
│   ├── Configuration/
│   │   └── Constants.swift             # App-wide constants
│   ├── Models/
│   │   ├── AppState.swift              # Observable app state
│   │   └── CollageItem.swift           # Canvas item data model
│   ├── ViewModels/
│   │   └── CollageViewModel.swift      # Canvas business logic
│   ├── Views/
│   │   ├── ContentView.swift           # Main container view
│   │   └── Components/
│   │       ├── CanvasContainerView.swift      # Size tracking wrapper
│   │       ├── CanvasView.swift               # Canvas rendering
│   │       ├── DraggableResizableItem.swift   # Interactive image view
│   │       ├── FloatingActionButtons.swift    # Action button overlay
│   │       ├── LoadingOverlay.swift           # Processing indicator
│   │       └── ErrorAlert.swift               # Error handling UI
│   ├── Services/
│   │   ├── ImageProcessingService.swift       # Image loading & processing
│   │   ├── BackgroundRemovalService.swift     # Vision framework integration
│   │   └── CanvasExportService.swift          # Canvas-to-image rendering
│   ├── Extensions/
│   │   ├── UIImage+Orientation.swift          # Orientation normalization
│   │   ├── UIImage+HitTest.swift              # Pixel opacity detection
│   │   └── PhotosPicker+Helpers.swift         # PhotosPicker utilities
│   └── Assets.xcassets/
└── README.md
```

### Key Technologies

- **SwiftUI**: Modern declarative UI framework
- **Vision Framework**: ML-powered foreground instance segmentation
- **Core Image**: Advanced image processing and border rendering
- **PhotosUI**: Native photo library picker integration
- **Observable**: SwiftUI's reactive state management (iOS 17+)
- **ImageRenderer**: High-quality SwiftUI view-to-image conversion

### Design Patterns

- **MVVM Architecture**: Clear separation of views, view models, and models
- **Protocol-Oriented Design**: All services use protocols for testability
- **Dependency Injection**: Services injected into view models
- **Observable State**: Centralized app state with SwiftUI's @Observable
- **Composition**: Small, focused components composed into complex UIs

## Technical Highlights

### Image Processing Pipeline

```swift
User selects photos from PhotosPicker
    ↓
Load image data and create UIImage
    ↓
Normalize orientation to .up (UIImage+Orientation)
    ↓
Remove background using Vision framework
    ↓
Crop to non-transparent bounding box
    ↓
Calculate initial size (1/3 canvas height)
    ↓
Create CollageItem and add to canvas
    ↓
User manipulates (gestures, layer controls)
    ↓
Render canvas to UIImage (ImageRenderer)
    ↓
Export via ShareSheet
```

### Background Removal Implementation

Uses Vision's `VNGenerateForegroundInstanceMaskRequest` for intelligent subject detection:

```swift
1. Convert UIImage to CIImage with proper orientation
2. Create Vision request handler
3. Generate foreground mask
4. Apply mask as alpha channel
5. Render final UIImage with transparency
```

### Cutout Border Rendering

Custom Core Image filter chain creates precise borders:

```swift
1. Morphological maximum filter (expand image)
2. Morphological minimum filter (smooth edges)
3. Difference blend with original
4. Composite with colored rectangle
```

## Requirements

- iOS 17.0+
- Xcode 15.0+
- Swift 5.9+
- Device with Neural Engine (for optimal Vision performance)

## Installation

### Clone the Repository

```bash
git clone https://github.com/erayalan/kolaj.git
cd kolaj
```

### Open in Xcode

```bash
open Kolaj.xcodeproj
```

### Build and Run

1. Select a target device or simulator (iOS 17.0+)
2. Press `Cmd + R` to build and run
3. Grant Photos library access when prompted

## Usage

### Basic Workflow

1. **Add Photos**: Tap the floating action button and select up to 20 photos
2. **Arrange**: Drag images to position, pinch to scale, rotate with two fingers
3. **Layer Control**: Tap or long-press layer buttons to adjust z-order
4. **Customize**: Add borders and change colors using the color picker buttons
5. **Export**: Tap the share button to save or share your collage

### Gesture Controls

| Gesture | Action |
|---------|--------|
| Single tap (on image) | Select item |
| Drag | Move selected item |
| Pinch | Scale selected item |
| Two-finger rotate | Rotate selected item |
| Drag corner handle | Resize from corner |
| Tap layer buttons | Move forward/backward |
| Long press layer buttons | Move to front/back |

## Configuration

### Constants

Edit `Constants.swift` to modify app behavior:

```swift
enum Constants {
    static let maxPhotoSelection = 20
    static let initialImageHeightRatio: CGFloat = 1.0 / 3.0
    static let cutoutBorderWidth: CGFloat = 20
    static let cornerHandleSize: CGFloat = 14
    static let cornerHandleTapAreaSize: CGFloat = 30
}
```

## Contributing

Contributions are welcome! Please follow these guidelines:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

### Code Style

- Follow Swift API Design Guidelines
- Use 4-space indentation
- Add comments for complex logic
- Write descriptive commit messages
- Ensure all builds succeed before submitting PR

## Testing

The project uses Swift Testing framework for unit tests and XCUITest for UI tests.

```bash
# Run all tests
cmd + U in Xcode

# Run specific test suite
xcodebuild test -scheme Kolaj -destination 'platform=iOS Simulator,name=iPhone 15'
```

## Roadmap

- [ ] Undo/Redo functionality
- [ ] Multiple canvas sizes and aspect ratios
- [ ] Shape tools (circles, squares, stars)
- [ ] Text overlay support
- [ ] Filters and effects
- [ ] Custom sticker library
- [ ] Template presets
- [ ] iCloud sync
- [ ] iPad support with multi-window

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Acknowledgments

- Built with SwiftUI and Apple's Vision framework
- Inspired by the quote: "Collage is the alchemy of the visual image" - Max Ernst
- Open source project

## Support

If you encounter any issues or have feature requests, please [open an issue](https://github.com/erayalan/kolaj/issues) on GitHub.

---

<p align="center">Made with ❤️ using SwiftUI</p>
