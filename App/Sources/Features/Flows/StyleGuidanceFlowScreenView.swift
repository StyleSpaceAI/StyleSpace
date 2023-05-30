import ComposableArchitecture
import SwiftUI

public struct StyleGuidanceFlowScreen: ReducerProtocol {
  public struct State: Equatable {
    var cameraPhoto: UIImage?
    var styleGuidanceImage: UIImage?
  }

  public enum Action: Equatable {
    case onCameraPhotoSaved(UIImage)
    case onStyleGuidanceImageSelected(UIImage)
    case submitFlow(cameraPhoto: UIImage, styleGuidanceImage: UIImage)
  }

  public var body: some ReducerProtocol<State, Action> {
    Reduce<State, Action> { state, action in
      switch action {
      case let .onCameraPhotoSaved(image):
        state.cameraPhoto = image
        return .none
      case let .onStyleGuidanceImageSelected(image):
        state.styleGuidanceImage = image
        return .none
      case .submitFlow:
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
    WithViewStore(self.store, observe: { $0 }) { viewStore in
      VStack(spacing: 40) {
        Button("Take a room photo") {
          viewStore.send(.onCameraPhotoSaved(UIImage()))
        }.buttonStyle(PrimaryButtonStyle())

        Button("Select a style guidance image") {
          viewStore.send(.onStyleGuidanceImageSelected(UIImage()))
        }.buttonStyle(PrimaryButtonStyle())
      }
      .padding([.leading, .trailing], 24)
      .padding([.top, .bottom], 24)
    }
  }
}
