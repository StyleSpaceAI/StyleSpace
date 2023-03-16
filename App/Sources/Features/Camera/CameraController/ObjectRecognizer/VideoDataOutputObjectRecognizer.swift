import AppDevUtils
import AVFoundation
import Dependencies
import UIKit.UIDevice
import Vision

// MARK: - YOLORecognizableObjects

enum YOLORecognizableObjects: String, CaseIterable {
  case person
  case bird
  case dog
  case horse
  case sheep
  case cow
  case elephant
  case bear
  case zebra
  case giraffe
}

// MARK: - VideoDataOutputObjectRecognizer

final class VideoDataOutputObjectRecognizer: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate {
  @Dependency(\.coreMLModelProvider) var coreMLModelProvider: CoreMLModelProvider

  /// Frame interval at which the object recognition request is performed.
  /// Larger value decreases resource drain but increases recognition delay.
  private let frameCountInterval = 10

  private let modelResourceName = "YOLOv3Int8LUT"
  private let modelResourceExtension = "mlmodelc"

  private let objectsToRecognize: Set<YOLORecognizableObjects>
  private let confidenceThreshold: Float
  private let onObservationChanged: (Set<YOLORecognizableObjects>) -> Void

  private var lastObservation = Set<YOLORecognizableObjects>() {
    willSet {
      if newValue != lastObservation {
        DispatchQueue.main.async { [weak self] in
          self?.onObservationChanged(newValue)
        }
      }
    }
  }

  private var objectRecognitionRequest: VNCoreMLRequest?

  private var frameCount = 0

  static func create(objectsToRecognize: Set<YOLORecognizableObjects> = Set(YOLORecognizableObjects.allCases),
                     confidenceThreshold: Float = 0.3,
                     onObservationChanged: @escaping (Set<YOLORecognizableObjects>) -> Void) async throws -> VideoDataOutputObjectRecognizer {
    let instance = VideoDataOutputObjectRecognizer(objectsToRecognize: objectsToRecognize,
                                                   confidenceThreshold: confidenceThreshold,
                                                   onObservationChanged: onObservationChanged)

    try await instance.setupObjectRecognition()

    return instance
  }

  private init(
    objectsToRecognize: Set<YOLORecognizableObjects>,
    confidenceThreshold: Float,
    onObservationChanged: @escaping (Set<YOLORecognizableObjects>) -> Void
  ) {
    self.objectsToRecognize = objectsToRecognize
    self.confidenceThreshold = confidenceThreshold
    self.onObservationChanged = onObservationChanged
  }

  public func captureOutput(_: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from _: AVCaptureConnection) {
    guard let objectRecognitionRequest else {
      assertionFailure("Delegate function called before object recognition request is initialized.")
      return
    }

    frameCount = (frameCount + 1) % frameCountInterval
    guard frameCount == 0 else { return }

    guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
      return
    }

    let orientation = DeviceOrientationHelper.realOrientation().asCGImagePropertyOrientation
    let imageRequestHandler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: orientation, options: [:])

    do {
      try imageRequestHandler.perform([objectRecognitionRequest])
    } catch {
      log.error("Error performing object detection request: \(error)")
    }
  }

  private func setupObjectRecognition() async throws {
    let visionModel = try await coreMLModelProvider.getModel(.yoloV3_8Bit)

    objectRecognitionRequest = VNCoreMLRequest(model: visionModel) { [weak self] request, _ in
      guard let self else { return }

      let recognizedObjects = request.results?
        .compactMap { $0 as? VNRecognizedObjectObservation }
        .filter {
          !$0.labels.isEmpty
            && $0.confidence >= self.confidenceThreshold
        }
        .map { $0.labels[0].identifier }
        .filter { self.objectsToRecognize.map(\.rawValue).contains($0) }
        .compactMap { YOLORecognizableObjects(rawValue: $0) }

      self.lastObservation = Set(recognizedObjects ?? [])
    }
  }
}
