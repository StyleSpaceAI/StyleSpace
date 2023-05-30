import ComposableArchitecture
import SwiftUI

public struct StyleGuidanceFlowScreen: ReducerProtocol {
  public struct State: Equatable, Hashable {
    var cameraPhoto: UIImage?
    var styleGuidanceImage: UIImage?
  }

  public enum Action: Equatable {
    case takePhoto
    case dismissCamera
    case chooseStyleGuideImage
    case submitFlow(cameraPhoto: UIImage, styleGuidanceImage: UIImage)

    case onCameraPhotoSaved(UIImage)
    case onStyleGuidanceImageSelected(UIImage)
  }

  public var body: some ReducerProtocol<State, Action> {
    Reduce<State, Action> { state, action in
      switch action {
      case .takePhoto:
        return .none

      case .dismissCamera:
        return .none

      case .chooseStyleGuideImage:
        return .none

      case .submitFlow:
        return .none

      case let .onCameraPhotoSaved(image):
        state.cameraPhoto = image
        return .send(.dismissCamera)

      case let .onStyleGuidanceImageSelected(image):
        state.styleGuidanceImage = image
        return .none
      }
    }
  }
}

struct StyleGuidanceFlowScreenView: View {
  let store: StoreOf<StyleGuidanceFlowScreen>

  public init(store: StoreOf<StyleGuidanceFlowScreen>) {
    self.store = store
  }

  var body: some View {
    WithViewStore(store, observe: { $0 }) { viewStore in
      VStack(spacing: 40) {
        if let cameraPhoto = viewStore.cameraPhoto {
          Image(uiImage: cameraPhoto)
        } else {
          Button("Take a room photo") {
            viewStore.send(.takePhoto)
          }
          .buttonStyle(PrimaryButtonStyle())
        }

        Button("Select a style guidance image") {
        }.buttonStyle(PrimaryButtonStyle())
      }
      .padding([.leading, .trailing], 24)
      .padding([.top, .bottom], 24)
    }
  }
}
