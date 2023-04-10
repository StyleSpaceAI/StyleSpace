import AppDevUtils
import AVFoundation
import Foundation
import SwiftUI
import Vision

// MARK: - CameraController

struct CameraController: UIViewControllerRepresentable {
  @ObservedObject var viewModel: CameraViewViewModel
  let onImageTaken: (UIImage) -> Void

  func makeUIViewController(context _: Context) -> CameraViewController {
    CameraViewController(viewModel: viewModel,
                         onImageTaken: onImageTaken) { lightLevel in
      viewModel.lightLevelPercentage = lightLevel
    }
  }

  func updateUIViewController(_ uiViewController: CameraViewController, context _: Context) {
    if viewModel.startPhotoCapture {
      uiViewController.capturePhoto()
    }
  }
}

// MARK: - CameraViewController

final class CameraViewController: UIViewController {
  private let viewModel: CameraViewViewModel
  private let onImageTaken: (UIImage) -> Void
  private let onLightLevelChanged: (Double) -> Void

  private var lightLevelISOListener: NSKeyValueObservation?
  private var deviceOrientationUponPhotoCapture: DeviceOrientationHelper.Orientation?

  // MARK: - AVFoundation related resources

  private let cameraSession = CameraSession()
  private var videoDeviceInput: AVCaptureDeviceInput?
  private let photoOutput: AVCapturePhotoOutput = {
    let photoOutput = AVCapturePhotoOutput()
    photoOutput.maxPhotoQualityPrioritization = photoQualityPrioritization
    return photoOutput
  }()

  private let videoDataOutput = {
    let output = AVCaptureVideoDataOutput()
    output.alwaysDiscardsLateVideoFrames = true
    output.videoSettings = [
      kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_420YpCbCr8BiPlanarFullRange),
    ]
    return output
  }()

  private var videoDataOutputDelegate: VideoDataOutputObjectRecognizer?

  private let videoDataOutputQueue = DispatchQueue(label: "VideoDataOutput", qos: .userInitiated, attributes: [], autoreleaseFrequency: .workItem)

  private static let photoQualityPrioritization: AVCapturePhotoOutput.QualityPrioritization = .quality

  init(viewModel: CameraViewViewModel,
       onImageTaken: @escaping (UIImage) -> Void,
       onLightLevelChanged: @escaping (Double) -> Void) {
    self.viewModel = viewModel
    self.onImageTaken = onImageTaken
    self.onLightLevelChanged = onLightLevelChanged

    super.init(nibName: nil, bundle: nil)

    Task { @MainActor in
      viewModel.state = .loading

      do {
        videoDataOutputDelegate = try await VideoDataOutputObjectRecognizer.create { [weak viewModel] detectedObjects in
          viewModel?.detectedObjects = detectedObjects
        }

        videoDataOutput.setSampleBufferDelegate(videoDataOutputDelegate, queue: videoDataOutputQueue)
      } catch {
        log.error("Failed to initialize VideoDataOutputObjectRecognizer: \(error). Object detection will not be available.")
      }
    }
  }

  @available(*, unavailable)
  required init?(coder _: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()

    if viewModel.state == .loading {
      configureCamera()
    }
  }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)

    Task.detached { [weak self] in
      await self?.cameraSession.startRunning()
    }
  }

  override func viewWillDisappear(_ animated: Bool) {
    Task.detached { [weak self] in
      await self?.cameraSession.stopRunning()
    }

    super.viewWillDisappear(animated)
  }

  deinit {
    lightLevelISOListener?.invalidate()
  }

  func capturePhoto() {
    Task {
      viewModel.startPhotoCapture = false
    }

    guard viewModel.state == .ready,
          let videoDeviceInput else {
      return
    }

    Task {
      viewModel.state = .capturing
    }

    let photoSettings = createPhotoSettings(videoDeviceInput)
    photoOutput.capturePhoto(with: photoSettings, delegate: self)
  }

  // MARK: - Private

  private func configureCamera() {
    guard let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
          let videoDeviceInput = try? AVCaptureDeviceInput(device: videoDevice)
    else {
      log.error("Unable to instantiate AVCaptureDevice")
      return
    }

    self.videoDeviceInput = videoDeviceInput

    setupVideoPreviewLayer()

    Task.detached { [weak self] in
      guard let self,
            let videoDeviceInput = await self.videoDeviceInput else { return }

      await self.cameraSession.configureSession(
        videoDeviceInput: videoDeviceInput,
        outputs: [self.photoOutput, self.videoDataOutput]
      )

      await MainActor.run { [weak self] in
        self?.viewModel.state = .ready
      }
    }

    lightLevelISOListener = videoDevice.observe(\.iso) { [weak self] device, _ in
      self?.onLightLevelChanged(videoDevice: device)
    }
  }

  private func setupVideoPreviewLayer() {
    let videoPreviewLayer = AVCaptureVideoPreviewLayer(session: cameraSession.captureSession)
    videoPreviewLayer.frame = view.frame

    let windowWidth = UIScreen.main.bounds.width
    let windowHeight = UIScreen.main.bounds.height
    videoPreviewLayer.anchorPoint = CGPoint(x: 0.5, y: 0.5)
    videoPreviewLayer.position = CGPoint(x: windowWidth / 2, y: windowHeight * 0.4)

    view.layer.addSublayer(videoPreviewLayer)
  }

  private func onLightLevelChanged(videoDevice: AVCaptureDevice) {
    let minISO = videoDevice.activeFormat.minISO
    let maxISO = videoDevice.activeFormat.maxISO

    let roomLightLevelPercentage = 100 - (100 * videoDevice.iso / (minISO + maxISO))

    viewModel.lightLevelPercentage = Double(roomLightLevelPercentage)
  }

  private func createPhotoSettings(_ videoDeviceInput: AVCaptureDeviceInput) -> AVCapturePhotoSettings {
    let photoSettings: AVCapturePhotoSettings

    // Enable HEIF format if supported
    if photoOutput.availablePhotoCodecTypes.contains(.hevc) {
      photoSettings = AVCapturePhotoSettings(format: [AVVideoCodecKey: AVVideoCodecType.hevc])
    } else {
      photoSettings = AVCapturePhotoSettings()
    }

    // Enable flash
    if videoDeviceInput.device.isFlashAvailable {
      photoSettings.flashMode = .auto
    }

    // Enable high-res photos
    if let maxPhotoDimensions = videoDeviceInput.device.activeFormat.supportedMaxPhotoDimensions.first {
      photoSettings.maxPhotoDimensions = maxPhotoDimensions
    }

    if let previewPhotoPixelFormatType = photoSettings.availablePreviewPhotoPixelFormatTypes.first {
      photoSettings.previewPhotoFormat = [kCVPixelBufferPixelFormatTypeKey as String: previewPhotoPixelFormatType]
    }

    photoSettings.photoQualityPrioritization = CameraViewController.photoQualityPrioritization

    return photoSettings
  }
}

// MARK: AVCapturePhotoCaptureDelegate

extension CameraViewController: AVCapturePhotoCaptureDelegate {
  enum DeviceOrientation {
    case portrait
    case portraitUpsideDown
    case landscapeLeft
    case landscapeRight
  }

  @MainActor
  public func photoOutput(_: AVCapturePhotoOutput, willCapturePhotoFor _: AVCaptureResolvedPhotoSettings) {
    deviceOrientationUponPhotoCapture = DeviceOrientationHelper.realOrientation()

    // Stop the capture session to achieve still frame while the photo is being processed
    Task.detached { [weak self] in
      await self?.cameraSession.stopRunning()
    }

    // Flash the screen to denote photo capture
    view.layer.opacity = 0
    UIView.animate(withDuration: 0.25) {
      self.view.layer.opacity = 1
    }
  }

  public func photoOutput(_: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
    defer { viewModel.state = .ready }

    if let error {
      log.error("Error capturing photo: \(error.localizedDescription)")
      return
    }

    guard let imageData = photo.fileDataRepresentation(),
          let image = UIImage(data: imageData)
    else {
      log.error("Error while extracting data from a processed photo")
      return
    }

    let fixedOrientationImage = fixedImageOrientation(image)

    onImageTaken(fixedOrientationImage)
  }

  // If the photo was taken in landscape mode (while the device was in fixed portrait mode), the image will be rotated
  private func fixedImageOrientation(_ image: UIImage) -> UIImage {
    guard let deviceOrientationUponPhotoCapture else {
      return image
    }

    switch deviceOrientationUponPhotoCapture {
    case .portraitUpsideDown:
      return image.rotated(to: .left)
    case .landscapeLeft:
      return image.rotated(to: .down)
    case .landscapeRight:
      return image.rotated(to: .up)
    case .portrait:
      return image
    }
  }
}
