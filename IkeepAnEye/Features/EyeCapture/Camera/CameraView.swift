import SwiftUI
import AVFoundation
import PhotosUI

struct CameraView: View {
    let onCapture: (EyePhoto) -> Void

    @StateObject private var sessionManager = CameraSessionManager()
    @StateObject private var uploadService = EyeUploadService()
    @State private var capturedImage: UIImage?
    @State private var isCapturing = false
    @State private var photosPickerItem: PhotosPickerItem?
    @State private var ellipsePulse = false
    @State private var uploadError: String?
    @Environment(\.dismiss) private var dismiss

    // True when there is no physical camera available (e.g. simulator on Mac Mini)
    private var cameraUnavailable: Bool {
        AVCaptureDevice.default(for: .video) == nil
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            if cameraUnavailable {
                // ── Photo library fallback (simulator / no camera) ──────────
                VStack(spacing: 24) {
                    Spacer()
                    Image(systemName: "camera.slash.fill")
                        .font(.system(size: 56))
                        .foregroundColor(.white.opacity(0.6))
                    Text("No camera available")
                        .font(.headline)
                        .foregroundColor(.white)
                    Text("Pick an eye photo from your library to continue.")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)

                    PhotosPicker(selection: $photosPickerItem, matching: .images) {
                        Text("Choose from Library")
                            .font(.headline)
                            .foregroundColor(.black)
                            .padding(.horizontal, 32)
                            .padding(.vertical, 14)
                            .background(Color.white)
                            .cornerRadius(12)
                    }
                    Spacer()
                    Button("Cancel") { dismiss() }
                        .foregroundColor(.white.opacity(0.7))
                        .padding(.bottom, 32)
                }
            } else {
                // ── Live camera preview ─────────────────────────────────────
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
                        Button {
                            Task { await sessionManager.switchCamera() }
                        } label: {
                            Image(systemName: "camera.rotate.fill")
                                .font(.title2)
                                .foregroundColor(.white)
                                .shadow(radius: 4)
                        }
                        // Library shortcut even when camera is present
                        PhotosPicker(selection: $photosPickerItem, matching: .images) {
                            Image(systemName: "photo.on.rectangle")
                                .font(.title2)
                                .foregroundColor(.white)
                                .shadow(radius: 4)
                        }
                    }
                    .padding()

                    Spacer()

                    // Instruction pill + rose ellipse guide
                    VStack(spacing: 8) {
                        Text("Centre your eye in the oval")
                            .font(.caption.weight(.medium))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(.ultraThinMaterial, in: Capsule())

                        Ellipse()
                            .strokeBorder(Color("BrandRose"), lineWidth: 2)
                            .frame(width: 300, height: 180)
                            .scaleEffect(ellipsePulse ? 1.06 : 1.0)
                            .animation(
                                .spring(response: 0.5, dampingFraction: 0.4),
                                value: ellipsePulse
                            )
                    }
                    .onAppear {
                        Task {
                            try? await Task.sleep(nanoseconds: 300_000_000)
                            ellipsePulse = true
                            try? await Task.sleep(nanoseconds: 600_000_000)
                            ellipsePulse = false
                        }
                    }

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
        }
        // Review sheet — used for both camera capture and library pick
        .sheet(isPresented: Binding(
            get: { capturedImage != nil },
            set: { if !$0 { capturedImage = nil; if !cameraUnavailable { sessionManager.start() } } }
        )) {
            if let img = capturedImage {
                CropReviewView(
                    image: img,
                    onAccept: { original, cropped, confidence in
                        capturedImage = nil
                        Task {
                            do {
                                let eyePhoto = try await uploadService.upload(
                                    original: original,
                                    cropped: cropped,
                                    confidence: confidence
                                )
                                onCapture(eyePhoto)
                            } catch {
                                uploadError = error.localizedDescription
                            }
                        }
                    },
                    onRetake: {
                        capturedImage = nil
                        if !cameraUnavailable { sessionManager.start() }
                    }
                )
            }
        }
        // Handle photo library selection
        .onChange(of: photosPickerItem) { item in
            guard let item else { return }
            Task {
                if let data = try? await item.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    capturedImage = image
                }
                photosPickerItem = nil
            }
        }
        .loadingOverlay(isCapturing || uploadService.isUploading)
        .errorAlert(message: $uploadError)
        .onAppear {
            AnalyticsService.shared.track("eye_capture_started")
        }
        .task {
            if !cameraUnavailable {
                await sessionManager.checkPermissionAndConfigure()
                sessionManager.start()
            }
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
            // fall through — user can retry
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
