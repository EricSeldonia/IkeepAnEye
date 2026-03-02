import CoreGraphics

/// Represents the detected eye region in UIKit coordinate space (top-left origin).
struct EyeRegion {
    /// Bounding rect in image-pixel coordinates (top-left origin).
    let rect: CGRect
    /// Vision detection confidence (0.0 – 1.0)
    let confidence: Double
    /// Which eye was selected for the pendant
    let eye: Eye

    enum Eye {
        case left, right
    }
}
