import AppDevUtils
import ComposableArchitecture
import IdentifiedCollections
import Inject
import SwiftUI

// MARK: - Root

public struct Root: ReducerProtocol {
  public struct State: Equatable, Codable {
    @BindingState var path = IdentifiedArrayOf<PathElement>()

    var alert: AlertState<Action>?

    var homeScreen = HomeScreen.State()
    var flowSelectionScreen = FlowSelectionScreen.State()
    var cameraScreen = CameraScreen.State()
    var uploadsScreen = UploadsScreen.State()

    enum CodingKeys: String, CodingKey {
      case homeScreen
    }
  }

  public enum Action: BindableAction, Equatable {
    case binding(BindingAction<State>)
    case task
    case saveState
    case alertDismissed
    case homeScreen(HomeScreen.Action)
    case flowSelectionScreen(FlowSelectionScreen.Action)
    case cameraScreen(CameraScreen.Action)
    case uploadsScreen(UploadsScreen.Action)
    case uploadResultsScreen(id: String, action: UploadResultsScreen.Action)
  }

  @Dependency(\.uploadsStorage) var uploadsStorage: UploadsStorageClient
  @Dependency(\.continuousClock) var clock
  @Dependency(\.coreMLModelProvider) var coreMLModelProvider: CoreMLModelProvider

  private enum TimerID {}

  public var body: some ReducerProtocol<State, Action> {
    CombineReducers {
      BindingReducer<State, Action>()

      Scope(state: \.homeScreen, action: /Action.homeScreen) {
        HomeScreen()
      }

      Scope(state: \.flowSelectionScreen, action: /Action.flowSelectionScreen) {
        FlowSelectionScreen()
      }

      Scope(state: \.cameraScreen, action: /Action.cameraScreen) {
        CameraScreen()
      }

      Scope(state: \.uploadsScreen, action: /Action.uploadsScreen) {
        UploadsScreen()
      }

      rootReducer

      routeReducer
    }
  }

  var routeReducer: some ReducerProtocolOf<Root> {
    Reduce<State, Action> { state, action in
      switch action {
      case let .uploadResultsScreen(id, resultAction):
        // We get the state of the screen from our route array
        guard var pathElement = state.path.first(where: { $0.route.uploadResultsState?.id == id }),
              var resultState = pathElement.route.uploadResultsState?.state else {
          log.error("Could not find upload results state for id: \(id)")
          assertionFailure()
          return .none
        }

        // Reduce
        let effect = UploadResultsScreen().reduce(into: &resultState, action: resultAction)

        // Assign back changed state
        pathElement.route = .uploadResults(id: id, state: resultState)
        state.path[id: pathElement.id] = pathElement

        // Return effect
        return effect.map { .uploadResultsScreen(id: id, action: $0) }

      default:
        return .none
      }
    }
  }

  var rootReducer: some ReducerProtocolOf<Root> {
    Reduce<State, Action> { state, action in
      switch action {
      case .binding:
        return .none

      case .task:
        Task { @MainActor in
          coreMLModelProvider.preloadModel(.yoloV3_8Bit)
        }

        return .run { send in
          // Triggering a save of the state every second
          for await _ in clock.timer(interval: .seconds(1)) {
            await send(.saveState)
          }
        }
        .cancellable(id: TimerID.self, cancelInFlight: true)

      case .saveState:
        RootStateStorage.saveState(state)
        return .none

      case .alertDismissed:
        state.alert = nil
        return .none

        // MARK: - HomeScreen

      case .homeScreen(.startRestylingButtonTapped):
        state.path.append(.flowSelection())
        return .none

      case .homeScreen(.galleryButtonTapped):
        state.path.append(.uploads())
        return .none

      case .homeScreen(.settingsButtonTapped):
        state.path.append(.settings())
        return .none

      case .homeScreen:
        return .none

        // MARK: - FlowSelectionScreen

      case .flowSelectionScreen(.startSinglePhotoFlow):
        state.path.append(.camera())
        return .none

      case .flowSelectionScreen(.startPhotoWithStyleGuidanceFlow):
        return .none

      case .flowSelectionScreen:
        return .none

        // MARK: - CameraScreen

//      case let .cameraScreen(.savePhoto(image)):
//        do {
//          let upload = Upload()
//          try uploadsStorage.saveImage(image, upload.id)
//          try uploadsStorage.addUpload(upload)
//          let uploadContainer = try uploadsStorage.getUploadContainer(upload.id).require()
//          state.path = [.uploads(), .uploadResults(id: upload.id, state: .init(upload: uploadContainer))]
//        } catch {
//          state.alert = somethingWrongAlert()
//        }
//        return .none

      case .cameraScreen:
        return .none

        // MARK: - UploadsScreen

      case let .uploadsScreen(.didTapUploadResults(id)):
        guard let upload = try? uploadsStorage.getUploadContainer(id) else {
          log.error("Upload not found: \(id)")
          return .none
        }
        state.path.append(.uploadResults(id: id, state: .init(upload: upload)))
        return .none

      case .uploadsScreen(.startRestylingButtonTapped):
        state.path = [.flowSelection()]
        return .none

      case .uploadsScreen:
        return .none

        // MARK: - UploadResultsScreen

      case let .uploadResultsScreen(_, .updateUploadProgress(.failed(error))):
        log.error("Upload failed: \(error)")
        state.alert = somethingWrongAlert()
        return .none

      case .uploadResultsScreen:
        return .none
      }
    }
  }

  func somethingWrongAlert() -> AlertState<Action> {
    AlertState(
      title: TextState("Error"),
      message: TextState("Something went wrong, please try again later"),
      dismissButton: .default(TextState("OK"), action: .send(.alertDismissed))
    )
  }
}

// MARK: - RootView

public struct RootView: View {
  @ObserveInjection var inject

  let store: StoreOf<Root>

  public init(store: StoreOf<Root>) {
    self.store = store
  }

  public var body: some View {
    WithViewStore(store, observe: { $0 }) { viewStore in
      NavigationStack(path: viewStore.binding(\.$path)) {
        HomeScreenView(store: store.scope(state: { $0.homeScreen }, action: { .homeScreen($0) }))
          .navigationDestination(for: PathElement.self) { pathElement in
            switch pathElement.route {
            case .flowSelection:
              FlowSelectionScreenView(store: store.scope(state: { $0.flowSelectionScreen }, action: { .flowSelectionScreen($0) }))

            case .camera:
              CameraScreenView(store: store.scope(state: { $0.cameraScreen }, action: { .cameraScreen($0) }))

            case .uploads:
              UploadsScreenView(store: store.scope(state: { $0.uploadsScreen }, action: { .uploadsScreen($0) }))

            case let .uploadResults(id, resultsState):
              UploadResultsScreenView(store: store.scope(state: { _ in resultsState }, action: { .uploadResultsScreen(id: id, action: $0) }))

            case .settings:
              SettingsScreenView()
            }
          }
      }
      .alert(
        store.scope(state: \.alert),
        dismiss: .alertDismissed
      )
      .task { viewStore.send(.task) }
    }
    .accentColor(.white)
    .enableInjection()
  }
}

#if DEBUG
  struct RootView_Previews: PreviewProvider {
    static var previews: some View {
      NavigationView {
        RootView(
          store: Store(
            initialState: Root.State(),
            reducer: Root()
          )
        )
      }
    }
  }
#endif
