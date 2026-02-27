import SwiftUI

/// Draggable, resizable circular crop overlay.
/// Uses .position() (not .offset()) so hit-test areas match visuals.
struct CropAdjustmentOverlay: View {
    @Binding var rect: CGRect
    let viewSize: CGSize

    @State private var lastDragTranslation: CGSize = .zero
    private let handleSize: CGFloat = 28
    private let minDiameter: CGFloat = 60

    var body: some View {
        ZStack(alignment: .topLeading) {
            // Dimming mask with circular cutout
            Color.black.opacity(0.5)
                .mask(
                    ZStack {
                        Rectangle()
                        Circle()
                            .frame(width: rect.width, height: rect.height)
                            .position(x: rect.midX, y: rect.midY)
                            .blendMode(.destinationOut)
                    }
                )
                .allowsHitTesting(false)

            // Draggable crop circle — .position() moves hit area too
            Circle()
                .strokeBorder(Color.white, lineWidth: 2)
                .frame(width: rect.width, height: rect.height)
                .position(x: rect.midX, y: rect.midY)
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            let dx = value.translation.width  - lastDragTranslation.width
                            let dy = value.translation.height - lastDragTranslation.height
                            lastDragTranslation = value.translation
                            rect.origin = clampedOrigin(
                                x: rect.origin.x + dx,
                                y: rect.origin.y + dy
                            )
                        }
                        .onEnded { _ in lastDragTranslation = .zero }
                )

            // Bottom-right resize handle
            Circle()
                .fill(Color.white)
                .shadow(radius: 2)
                .frame(width: handleSize, height: handleSize)
                .position(x: rect.maxX, y: rect.maxY)
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            let delta = (value.translation.width + value.translation.height) / 2
                            let newSize = max(minDiameter, rect.width + delta)
                            rect = CGRect(
                                origin: clampedOrigin(x: rect.origin.x, y: rect.origin.y),
                                size: CGSize(width: newSize, height: newSize)
                            )
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
