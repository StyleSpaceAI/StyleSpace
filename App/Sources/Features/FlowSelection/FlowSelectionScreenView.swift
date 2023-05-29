import ComposableArchitecture
import SwiftUI

// MARK: - FlowSelectionScreen

public struct FlowSelectionScreen: ReducerProtocol {
  public struct State: Equatable {
    var cameraScreen = CameraScreen.State()
  }

  public enum Action: Equatable {
    case startSinglePhotoFlow
    case startPhotoWithStyleGuidanceFlow
    case cameraScreen(CameraScreen.Action)
  }

  public var body: some ReducerProtocol<State, Action> {
    CombineReducers {
      Scope(state: \.cameraScreen, action: /Action.cameraScreen) {
        CameraScreen()
      }
      Reduce<State, Action> { _, action in
        switch action {
        case .startSinglePhotoFlow:
          return .none
        case .startPhotoWithStyleGuidanceFlow:
          return .none
        case .cameraScreen:
          return .none
        }
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
//    WithViewStore(self.store, observe: { $0 }) { viewStore in
      VStack(spacing: 100) {

        NavigationLink(
          destination: CameraScreenView(store: self.store.scope(state: \.cameraScreen, action: { .cameraScreen($0) }))
        ) {
          Text("Single photo")
        }

//        Button("Photo with Style Guidance") {
//          viewStore.send(.startPhotoWithStyleGuidanceFlow)
//        }.buttonStyle(PrimaryButtonStyle())
      }
      .padding([.leading, .trailing], 24)
      .padding([.top, .bottom], 24)
    }
//  }
}

#if DEBUG
  struct FlowSelectionScreenView_Previews: PreviewProvider {
    static var previews: some View {
      FlowSelectionScreenView(
        store: Store(
          initialState: FlowSelectionScreen.State(),
          reducer: FlowSelectionScreen()
        )
      )
    }
  }
#endif
