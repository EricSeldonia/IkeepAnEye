import SwiftUI

/// Displays a draggable, resizable circular crop overlay on top of the preview image.
struct CropAdjustmentOverlay: View {
    @Binding var rect: CGRect    // In view-coordinate space
    let viewSize: CGSize

    @State private var lastDragOffset: CGSize = .zero
    private let handleSize: CGFloat = 28
    private let minDiameter: CGFloat = 60

    var body: some View {
        ZStack {
            // Dim area outside the crop circle
            Rectangle()
                .fill(Color.black.opacity(0.5))
                .mask(
                    Rectangle()
                        .overlay(
                            Circle()
                                .frame(width: rect.width, height: rect.height)
                                .offset(
                                    x: rect.midX - viewSize.width  / 2,
                                    y: rect.midY - viewSize.height / 2
                                )
                                .blendMode(.destinationOut)
                        )
                )
                .allowsHitTesting(false)

            // Crop circle outline — drag to reposition
            Circle()
                .strokeBorder(Color.white, lineWidth: 2)
                .frame(width: rect.width, height: rect.height)
                .offset(
                    x: rect.midX - viewSize.width  / 2,
                    y: rect.midY - viewSize.height / 2
                )
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            let deltaX = value.translation.width  - lastDragOffset.width
                            let deltaY = value.translation.height - lastDragOffset.height
                            lastDragOffset = value.translation
                            rect.origin = clampedOrigin(
                                x: rect.origin.x + deltaX,
                                y: rect.origin.y + deltaY
                            )
                        }
                        .onEnded { _ in lastDragOffset = .zero }
                )

            // Bottom-right resize handle
            Circle()
                .fill(Color.white)
                .frame(width: handleSize, height: handleSize)
                .shadow(radius: 2)
                .offset(
                    x: rect.maxX - viewSize.width  / 2 - handleSize / 2,
                    y: rect.maxY - viewSize.height / 2 - handleSize / 2
                )
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            let delta = (value.translation.width + value.translation.height) / 2
                            let newSize = max(minDiameter, rect.width + delta)
                            rect.size = CGSize(width: newSize, height: newSize)
                            rect.origin = clampedOrigin(x: rect.origin.x, y: rect.origin.y)
                        }
                )
        }
        .frame(width: viewSize.width, height: viewSize.height)
    }

    private func clampedOrigin(x: CGFloat, y: CGFloat) -> CGPoint {
        CGPoint(
            x: min(max(0, x), viewSize.width  - rect.width),
            y: min(max(0, y), viewSize.height - rect.height)
        )
    }
}
