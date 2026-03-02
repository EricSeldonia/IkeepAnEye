import UIKit
@preconcurrency import Vision

/// Runs on-device eye detection using Vision framework.
/// All processing happens on a background queue — never blocks the main thread.
final class EyeDetectionService {

    enum DetectionError: LocalizedError {
        case noFaceDetected
        case noLandmarksDetected
        case imageConversionFailed

        var errorDescription: String? {
            switch self {
            case .noFaceDetected:        return "No face detected in the image."
            case .noLandmarksDetected:   return "Face detected but eye landmarks could not be located."
            case .imageConversionFailed: return "Could not prepare the image for analysis."
            }
        }
    }

    /// Detects the eye region in `image`, returning the highest-confidence result.
    /// Throws `DetectionError` if detection fails.
    func detect(in image: UIImage) async throws -> EyeRegion {
        guard let cgImage = image.cgImage else { throw DetectionError.imageConversionFailed }

        return try await withCheckedThrowingContinuation { continuation in
            var resumed = false
            func resume(with result: Result<EyeRegion, Error>) {
                guard !resumed else { return }
                resumed = true
                switch result {
                case .success(let r): continuation.resume(returning: r)
                case .failure(let e): continuation.resume(throwing: e)
                }
            }

            let request = VNDetectFaceLandmarksRequest { request, error in
                if let error {
                    resume(with: .failure(error))
                    return
                }
                do {
                    let region = try self.process(request: request, imageSize: image.size)
                    resume(with: .success(region))
                } catch {
                    resume(with: .failure(error))
                }
            }
            request.revision = VNDetectFaceLandmarksRequestRevision3

            // Create handler inside the async closure to satisfy Sendable requirements
            DispatchQueue.global(qos: .userInitiated).async {
                let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
                do {
                    try handler.perform([request])
                } catch {
                    resume(with: .failure(error))
                }
            }
        }
    }

    // MARK: - Private

    private func process(request: VNRequest, imageSize: CGSize) throws -> EyeRegion {
        guard let observations = request.results as? [VNFaceObservation],
              let observation = observations.max(by: { $0.confidence < $1.confidence })
        else { throw DetectionError.noFaceDetected }

        guard let landmarks = observation.landmarks else { throw DetectionError.noLandmarksDetected }

        // Pick the eye region with more normalizedPoints (better landmark coverage)
        let leftEye  = landmarks.leftEye
        let rightEye = landmarks.rightEye

        let chosenEye: VNFaceLandmarkRegion2D
        let eyeEnum: EyeRegion.Eye

        switch (leftEye, rightEye) {
        case let (l?, r?):
            if l.normalizedPoints.count >= r.normalizedPoints.count {
                chosenEye = l; eyeEnum = .left
            } else {
                chosenEye = r; eyeEnum = .right
            }
        case (let l?, nil): chosenEye = l; eyeEnum = .left
        case (nil, let r?): chosenEye = r; eyeEnum = .right
        default: throw DetectionError.noLandmarksDetected
        }

        let eyePoints = chosenEye.normalizedPoints
        guard !eyePoints.isEmpty else {
            throw DetectionError.noLandmarksDetected
        }

        // Also collect eyebrow landmarks for the chosen eye
        let browRegion: VNFaceLandmarkRegion2D? = (eyeEnum == .left) ? landmarks.leftEyebrow : landmarks.rightEyebrow
        let browPoints = browRegion?.normalizedPoints ?? []

        // Combine eye + eyebrow points for the bounding region
        let combinedPoints = eyePoints + browPoints

        // Points are relative to the face bounding box — convert to full-image normalized space
        let faceBB = observation.boundingBox
        let imagePoints: [CGPoint] = combinedPoints.map { pt in
            CGPoint(
                x: faceBB.origin.x + pt.x * faceBB.width,
                y: faceBB.origin.y + pt.y * faceBB.height
            )
        }

        guard let minX = imagePoints.map(\.x).min(),
              let maxX = imagePoints.map(\.x).max(),
              let minY = imagePoints.map(\.y).min(),
              let maxY = imagePoints.map(\.y).max() else {
            throw DetectionError.noLandmarksDetected
        }

        var visionRect = CGRect(x: minX, y: minY, width: maxX - minX, height: maxY - minY)

        // Directional padding: wider horizontally, more below the eye for cheek skin,
        // less on top since the eyebrow is already included.
        // If eyebrow landmarks were unavailable, add extra top padding to estimate brow position.
        let padX      = visionRect.width  * 0.20
        let padTop    = browPoints.isEmpty ? visionRect.height * 0.60 : visionRect.height * 0.15
        let padBottom = visionRect.height * 0.35

        visionRect = CGRect(
            x:      visionRect.minX - padX,
            y:      visionRect.minY - padBottom, // Vision y grows upward; subtract to expand downward in UIKit
            width:  visionRect.width  + padX * 2,
            height: visionRect.height + padTop + padBottom
        )
        visionRect = visionRect.intersection(CGRect(x: 0, y: 0, width: 1, height: 1))

        // Convert Vision space (bottom-left origin, normalized) → UIKit pixel space
        let uiRect = UIImage.visionRectToUIKit(visionRect, imageSize: imageSize)

        return EyeRegion(
            rect: uiRect,
            confidence: Double(observation.confidence),
            eye: eyeEnum
        )
    }
}
