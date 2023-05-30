import ComposableArchitecture
import SwiftUI

// MARK: - FlowSelectionScreen

public struct FlowSelectionScreen: ReducerProtocol {
  public struct State: Equatable, Hashable {
    var cameraPhoto: UIImage?
  }

  public enum Action: Equatable {
    case startSinglePhotoFlow
    case startPhotoWithStyleGuidanceFlow
    case onCameraPhotoSaved(UIImage)
    case submitSinglePhotoFlow(cameraPhoto: UIImage)
  }

  public var body: some ReducerProtocol<State, Action> {
    Reduce<State, Action> { state, action in
      switch action {
      case .startSinglePhotoFlow:
        return .none
      case .startPhotoWithStyleGuidanceFlow:
        return .none
      case let .onCameraPhotoSaved(image):
        return .send(.submitSinglePhotoFlow(cameraPhoto: image))
      case .submitSinglePhotoFlow:
        return .none
      }
    }
  }
}

// MARK: - FlowSelectionScreenView

struct FlowSelectionScreenView: View {
  let store: StoreOf<FlowSelectionScreen>

  public init(store: StoreOf<FlowSelectionScreen>) {
    self.store = store
  }

  var body: some View {
    WithViewStore(self.store, observe: { $0 }) { viewStore in
      VStack(spacing: 100) {
        Button("Single photo") {
          viewStore.send(.startSinglePhotoFlow)
        }.buttonStyle(PrimaryButtonStyle())

        Button("Photo with style guidance") {
          viewStore.send(.startPhotoWithStyleGuidanceFlow)
        }.buttonStyle(PrimaryButtonStyle())
      }
      .padding([.leading, .trailing], 24)
      .padding([.top, .bottom], 24)
    }
  }
}

#if DEBUG
  struct FlowSelectionScreenView_Previews: PreviewProvider {
    static var previews: some View {
      FlowSelectionScreenView(
        store: Store(
          initialState: FlowSelectionScreen.State(cameraPhoto: nil),
          reducer: FlowSelectionScreen()
        )
      )
    }
  }
#endif
