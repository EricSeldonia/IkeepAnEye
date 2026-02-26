import SwiftUI
import AVFoundation

struct CameraView: View {
    let onCapture: (UIImage) -> Void

    @StateObject private var sessionManager = CameraSessionManager()
    @State private var capturedImage: UIImage?
    @State private var isCapturing = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            CameraPreviewLayer(session: sessionManager.session)
                .ignoresSafeArea()

            VStack {
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title)
                            .foregroundColor(.white)
                            .shadow(radius: 4)
                    }
                    Spacer()
                }
                .padding()

                Spacer()

                // Oval guide overlay
                Ellipse()
                    .strokeBorder(Color.white.opacity(0.7), lineWidth: 2)
                    .frame(width: 220, height: 160)

                Text("Position your eye inside the oval")
                    .font(.caption)
                    .foregroundColor(.white)
                    .shadow(radius: 2)
                    .padding(.top, 8)

                Spacer()

                Button {
                    Task { await captureAndReview() }
                } label: {
                    ZStack {
                        Circle()
                            .stroke(Color.white.opacity(0.5), lineWidth: 4)
                            .frame(width: 80, height: 80)
                        Circle()
                            .fill(Color.white)
                            .frame(width: 66, height: 66)
                    }
                }
                .disabled(isCapturing)
                .padding(.bottom, 48)
            }
        }
        .sheet(isPresented: Binding(
            get: { capturedImage != nil },
            set: { if !$0 { capturedImage = nil; sessionManager.start() } }
        )) {
            if let img = capturedImage {
                CropReviewView(
                    image: img,
                    onAccept: { cropped in
                        capturedImage = nil
                        onCapture(cropped)
                    },
                    onRetake: {
                        capturedImage = nil
                        sessionManager.start()
                    }
                )
            }
        }
        .loadingOverlay(isCapturing)
        .task {
            await sessionManager.checkPermissionAndConfigure()
            sessionManager.start()
        }
        .onDisappear { sessionManager.stop() }
        .alert("Camera Access Denied", isPresented: $sessionManager.permissionDenied) {
            Button("Open Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            Button("Cancel", role: .cancel) { dismiss() }
        } message: {
            Text("Enable camera access in Settings to photograph your eye.")
        }
    }

    private func captureAndReview() async {
        isCapturing = true
        defer { isCapturing = false }
        do {
            let image = try await sessionManager.capturePhoto()
            sessionManager.stop()
            capturedImage = image
        } catch {
            // In a shipping app, show an error alert here
        }
    }
}

/// SwiftUI wrapper for AVCaptureVideoPreviewLayer.
struct CameraPreviewLayer: UIViewRepresentable {
    let session: AVCaptureSession

    func makeUIView(context: Context) -> PreviewView {
        let view = PreviewView()
        view.previewLayer.session = session
        view.previewLayer.videoGravity = .resizeAspectFill
        return view
    }

    func updateUIView(_ uiView: PreviewView, context: Context) {}

    class PreviewView: UIView {
        override class var layerClass: AnyClass { AVCaptureVideoPreviewLayer.self }
        var previewLayer: AVCaptureVideoPreviewLayer { layer as! AVCaptureVideoPreviewLayer }
    }
}
