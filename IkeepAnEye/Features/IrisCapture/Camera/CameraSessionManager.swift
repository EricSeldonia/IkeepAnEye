import AVFoundation
import UIKit

/// Manages the AVCaptureSession for front-camera still photo capture.
@MainActor
final class CameraSessionManager: NSObject, ObservableObject {
    let session = AVCaptureSession()

    @Published var isRunning = false
    @Published var permissionDenied = false

    private var photoOutput = AVCapturePhotoOutput()
    private var photoContinuation: CheckedContinuation<UIImage, Error>?

    override init() {
        super.init()
    }

    func checkPermissionAndConfigure() async {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            await configure()
        case .notDetermined:
            let granted = await AVCaptureDevice.requestAccess(for: .video)
            if granted { await configure() } else { permissionDenied = true }
        default:
            permissionDenied = true
        }
    }

    func start() {
        guard !session.isRunning else { return }
        Task.detached { [session] in session.startRunning() }
        isRunning = true
    }

    func stop() {
        guard session.isRunning else { return }
        Task.detached { [session] in session.stopRunning() }
        isRunning = false
    }

    func capturePhoto() async throws -> UIImage {
        try await withCheckedThrowingContinuation { [weak self] cont in
            guard let self else {
                cont.resume(throwing: CameraError.sessionUnavailable)
                return
            }
            self.photoContinuation = cont
            let settings = AVCapturePhotoSettings()
            settings.flashMode = .off
            self.photoOutput.capturePhoto(with: settings, delegate: self)
        }
    }

    // MARK: - Private

    private func configure() async {
        session.beginConfiguration()
        session.sessionPreset = .photo

        // Prefer front camera; fall back to any available video device (e.g. USB webcam)
        let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front)
            ?? AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back)
            ?? AVCaptureDevice.default(for: .video)

        guard let device,
              let input = try? AVCaptureDeviceInput(device: device),
              session.canAddInput(input) else {
            session.commitConfiguration()
            return
        }
        session.addInput(input)

        if session.canAddOutput(photoOutput) {
            session.addOutput(photoOutput)
            photoOutput.isHighResolutionCaptureEnabled = true
        }
        session.commitConfiguration()
    }
}

extension CameraSessionManager: AVCapturePhotoCaptureDelegate {
    nonisolated func photoOutput(
        _ output: AVCapturePhotoOutput,
        didFinishProcessingPhoto photo: AVCapturePhoto,
        error: Error?
    ) {
        Task { @MainActor [weak self] in
            guard let self else { return }
            if let error {
                photoContinuation?.resume(throwing: error)
            } else if let data = photo.fileDataRepresentation(),
                      let image = UIImage(data: data) {
                photoContinuation?.resume(returning: image)
            } else {
                photoContinuation?.resume(throwing: CameraError.captureDataUnavailable)
            }
            photoContinuation = nil
        }
    }
}

enum CameraError: LocalizedError {
    case sessionUnavailable
    case captureDataUnavailable

    var errorDescription: String? {
        switch self {
        case .sessionUnavailable:      return "Camera session is not available."
        case .captureDataUnavailable:  return "Could not retrieve the captured photo."
        }
    }
}
