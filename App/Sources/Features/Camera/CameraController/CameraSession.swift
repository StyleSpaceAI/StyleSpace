import AppDevUtils
import AVFoundation

actor CameraSession {
  let captureSession = AVCaptureSession()

  private var isRunning = false

  func startRunning() {
    guard !isRunning else { return }
    isRunning = true
    captureSession.startRunning()
  }

  func stopRunning() {
    guard isRunning else { return }
    isRunning = false
    captureSession.stopRunning()
  }

  func configureSession(videoDeviceInput: AVCaptureInput, outputs: [AVCaptureOutput]) {
    captureSession.beginConfiguration()

    // Input
    captureSession.addInput(videoDeviceInput)

    // Output
    captureSession.sessionPreset = .photo

    for output in outputs {
      if captureSession.canAddOutput(output) {
        captureSession.addOutput(output)
      } else {
        log.error("Unable to add output: \(output)")
      }
    }

    captureSession.commitConfiguration()
  }
}
