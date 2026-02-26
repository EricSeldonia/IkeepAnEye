import UIKit

extension UIImage {
    /// Crops the image to the given rect (in image-space pixels).
    func cropped(to rect: CGRect) -> UIImage? {
        guard let cgImage = self.cgImage else { return nil }
        let scale = self.scale
        let scaledRect = CGRect(
            x: rect.origin.x * scale,
            y: rect.origin.y * scale,
            width: rect.width * scale,
            height: rect.height * scale
        )
        guard let cropped = cgImage.cropping(to: scaledRect) else { return nil }
        return UIImage(cgImage: cropped, scale: scale, orientation: self.imageOrientation)
    }

    /// Returns a new image scaled to the given size.
    func scaled(to size: CGSize) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { _ in
            self.draw(in: CGRect(origin: .zero, size: size))
        }
    }

    /// Returns a circular-cropped version of the image (centered square, then masked).
    var circularCropped: UIImage {
        let minSide = min(size.width, size.height)
        let squareSize = CGSize(width: minSide, height: minSide)
        let origin = CGPoint(
            x: (size.width - minSide) / 2,
            y: (size.height - minSide) / 2
        )
        let renderer = UIGraphicsImageRenderer(size: squareSize)
        return renderer.image { ctx in
            let rect = CGRect(origin: .zero, size: squareSize)
            UIBezierPath(ovalIn: rect).addClip()
            draw(at: CGPoint(x: -origin.x, y: -origin.y))
        }
    }

    /// Converts a Vision-space CGRect (bottom-left origin, normalized) to
    /// a UIKit-space pixel CGRect (top-left origin) for the given image dimensions.
    static func visionRectToUIKit(_ visionRect: CGRect, imageSize: CGSize) -> CGRect {
        let x = visionRect.origin.x * imageSize.width
        // Vision uses bottom-left origin; UIKit uses top-left
        let y = (1 - visionRect.origin.y - visionRect.height) * imageSize.height
        let w = visionRect.width * imageSize.width
        let h = visionRect.height * imageSize.height
        return CGRect(x: x, y: y, width: w, height: h)
    }
}
