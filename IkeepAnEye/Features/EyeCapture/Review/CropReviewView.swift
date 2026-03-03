import SwiftUI

struct CropReviewView: View {
    let image: UIImage
    let onAccept: (UIImage) -> Void
    let onRetake: () -> Void

    @State private var cropRect: CGRect = .zero
    @State private var isDetecting = true
    @State private var viewSize: CGSize = .zero

    private let detectionService = EyeDetectionService()

    var body: some View {
        NavigationStack {
            GeometryReader { geo in
                ZStack {
                    Color.black.ignoresSafeArea()

                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(width: geo.size.width, height: geo.size.height)

                    if !cropRect.isEmpty {
                        CropAdjustmentOverlay(rect: $cropRect, viewSize: geo.size)
                    }

                    if isDetecting {
                        ProgressView("Detecting eye…")
                            .padding(16)
                            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 10))
                    }

                    // Drag hint caption
                    VStack {
                        Spacer()
                        Text("Drag to reposition · Resize from corner")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.bottom, 8)
                    }
                }
                .onAppear {
                    viewSize = geo.size
                    // Always set a default crop immediately so "Looks Good →" is never blocked
                    setDefaultCrop(in: geo.size)
                    Task { await runDetection(in: geo.size) }
                }
            }
            .ignoresSafeArea(edges: .bottom)
            .navigationTitle("Adjust Crop")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Retake") { onRetake() }
                        .foregroundColor(.secondary)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Looks Good →") { acceptCrop() }
                        .bold()
                        .foregroundColor(Color("BrandRose"))
                }
            }
        }
    }

    // MARK: - Detection

    private func runDetection(in containerSize: CGSize) async {
        do {
            let region = try await detectionService.detect(in: image)
            // Update crop rect with detected eye position
            cropRect = imageRectToViewRect(region.rect, containerSize: containerSize)
        } catch {
            // Detection failed — default crop set in onAppear remains active
        }
        isDetecting = false
    }

    // MARK: - Crop helpers

    private func setDefaultCrop(in containerSize: CGSize) {
        let width  = min(containerSize.width, containerSize.height) * 0.7
        let height = width * (2.0 / 3.0)
        cropRect = CGRect(
            x: (containerSize.width  - width)  / 2,
            y: (containerSize.height - height) / 2,
            width: width,
            height: height
        )
    }

    private func acceptCrop() {
        let imageRect = viewRectToImageRect(cropRect)
        guard let cropped = image.cropped(to: imageRect) else { return }
        AnalyticsService.shared.track("eye_capture_completed")
        onAccept(cropped.ovalCropped)
    }

    // MARK: - Coordinate conversion

    private func imageRectToViewRect(_ imageRect: CGRect, containerSize: CGSize) -> CGRect {
        let scale = min(containerSize.width  / image.size.width,
                        containerSize.height / image.size.height)
        let scaledW = image.size.width  * scale
        let scaledH = image.size.height * scale
        let offsetX = (containerSize.width  - scaledW) / 2
        let offsetY = (containerSize.height - scaledH) / 2
        return CGRect(
            x: imageRect.origin.x * scale + offsetX,
            y: imageRect.origin.y * scale + offsetY,
            width:  imageRect.width  * scale,
            height: imageRect.height * scale
        )
    }

    private func viewRectToImageRect(_ viewRect: CGRect) -> CGRect {
        let scale = min(viewSize.width  / image.size.width,
                        viewSize.height / image.size.height)
        let scaledW = image.size.width  * scale
        let scaledH = image.size.height * scale
        let offsetX = (viewSize.width  - scaledW) / 2
        let offsetY = (viewSize.height - scaledH) / 2
        return CGRect(
            x: (viewRect.origin.x - offsetX) / scale,
            y: (viewRect.origin.y - offsetY) / scale,
            width:  viewRect.width  / scale,
            height: viewRect.height / scale
        )
    }
}
