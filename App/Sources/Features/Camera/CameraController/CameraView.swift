import CameraButton
import SwiftUI

// MARK: - CameraViewViewModel

@MainActor
final class CameraViewViewModel: ObservableObject {
  enum State {
    case loading
    case ready
    case capturing
  }

  /// Signals the camera controller to start photo capture.
  @Published public var startPhotoCapture = false
  @Published public var state: State = .loading
  @Published public var lightLevelPercentage: Double?
  @Published public var detectedObjects = Set<YOLORecognizableObjects>()
}

// MARK: - CameraView

struct CameraView: View {
  @StateObject var viewModel = CameraViewViewModel()
  @StateObject var componentCoordinator = GuidanceOverlayCoordinator()
  let onImageTaken: (UIImage) -> Void

  var body: some View {
    CameraController(viewModel: viewModel) { image in
      onImageTaken(image)
    }
    .overlay(alignment: .bottom) {
      CameraButtonUI(
        progressDuration: 5,
        isRecording: .constant(false)
      )
      .simultaneousGesture(
        TapGesture()
          .onEnded { _ in
            viewModel.startPhotoCapture = true
          }
      )
      .disabled(viewModel.state != .ready)
    }
    .overlay(alignment: .top) {
      if viewModel.state == .ready {
        UserGuidanceOverlayView { component in
          switch component {
          case .level:
            LevelComponentView()
          case .illumination:
            IlluminationComponentView()
          case .objectDetection:
            ObjectDetectionComponentView(detectedObjects: $viewModel.detectedObjects)
          }
        }
        .environmentObject(componentCoordinator)
      }
    }
    .onAppear {
      componentCoordinator.setComponents([
        .level,
        .illumination(lightLevelPercentage: viewModel.$lightLevelPercentage),
        .objectDetection(detectedObjects: viewModel.$detectedObjects),
      ])
    }
  }
}
