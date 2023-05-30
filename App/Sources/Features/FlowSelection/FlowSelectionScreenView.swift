import ComposableArchitecture
import SwiftUI

// MARK: - FlowSelectionScreen

public struct FlowSelectionScreen: ReducerProtocol {
  public struct State: Equatable, Hashable {
    enum Flow {
      case selection
      case singlePhoto
      case photoWithStyleGuidance
    }

    var flow: Flow = .selection
    var cameraPhoto: UIImage?
    var styleGuidanceImage: UIImage?
  }

  public enum Action: Equatable {
    case startSinglePhotoFlow
    case startPhotoWithStyleGuidanceFlow
    case cameraPhotoSaved(UIImage)
  }

  public var body: some ReducerProtocol<State, Action> {
    Reduce<State, Action> { state, action in
      switch action {
      case .startSinglePhotoFlow:
        state.flow = .singlePhoto
        return .none
      case .startPhotoWithStyleGuidanceFlow:
        state.flow = .photoWithStyleGuidance
        return .none
      case let .cameraPhotoSaved(image):
        print(image)
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
        Button("Single Photo") {
          viewStore.send(.startSinglePhotoFlow)
        }.buttonStyle(PrimaryButtonStyle())

        Button("Photo with Style Guidance") {
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
          initialState: FlowSelectionScreen.State(cameraPhoto: nil, styleGuidanceImage: nil),
          reducer: FlowSelectionScreen()
        )
      )
    }
  }
#endif
