import CameraButton
import SwiftUI

// MARK: - CameraViewViewModel

@MainActor
final class CameraViewViewModel: ObservableObject {
  @Published public var capturePhoto = false
  @Published public var capturingPhoto = false
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
      viewModel.capturingPhoto = false
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
            viewModel.capturePhoto = true
          }
      )
      .disabled(viewModel.capturingPhoto)
    }
    .overlay(alignment: .top) {
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
    .onAppear {
      componentCoordinator.setComponents([
        .level,
        .illumination(lightLevelPercentage: viewModel.$lightLevelPercentage),
        .objectDetection(detectedObjects: viewModel.$detectedObjects)
      ])
    }
  }
}
