import AppDevUtils
import ComposableArchitecture
import Inject
import Introspect
import LottieUI
import NukeUI
import SwiftUI

// MARK: - UploadResultsScreen

public struct UploadResultsScreen: ReducerProtocol {
  static let maxImagesToDownload = 14

  public struct State: Hashable, Identifiable {
    public var id: String { upload.id }

    var upload: UploadContainer
    var selectedId: ResultDetails.State.ID? = nil

    var results: IdentifiedArrayOf<ResultDetails.State> = []
    var currentStageRunTime: TimeInterval = 0
    var currentStageStartDate = Date()

    var requiresUpload: Bool {
      upload.status == .uploading(.notStarted)
    }

    var isBrokenUpload: Bool {
      upload.creationDate < Date().addingTimeInterval(-60 * 10)
        && upload.status.isDownloading
        && upload.interiorDesigns.isEmpty
    }
  }

  public enum Action: Equatable {
    case task
    case setSheet(selectedId: ResultDetails.State.ID?)

    case updateUploadProgress(Progress)
    case didFinishDownloadingResults(TaskResult<[URL]>)
    case refreshCurrentRunTimer

    case result(id: ResultDetails.State.ID, action: ResultDetails.Action)
  }

  @Dependency(\.backend) var backendClient: BackendClient
  @Dependency(\.uploadsStorage) var uploadsStorage: UploadsStorageClient
  @Dependency(\.continuousClock) var clock
  private struct TimerID: Hashable {}

  public var body: some ReducerProtocol<State, Action> {
    Reduce<State, Action> { state, action in
      switch action {
      case .task:
        if state.isBrokenUpload {
          log.verbose("Broken upload, starting upload task")
          state.upload.creationDate = Date()
          return uploadImage(state: state)
        } else if state.requiresUpload {
          log.verbose("Requires upload, starting upload task")
          return uploadImage(state: state)
        } else {
          log.verbose("Does not require upload, starting download task")
          return downloadImages(state: &state)
        }

      case let .setSheet(selectedId):
        state.selectedId = selectedId
        return .none

      case let .updateUploadProgress(progress):
        state.upload.status = .uploading(progress)
        if case .completed = progress {
          return downloadImages(state: &state)
        }
        return .none

      case let .didFinishDownloadingResults(.failure(error)):
        state.upload.status = .downloading(.failed(error.equatable))
        log.error("Error fetching images: \(error)")
        return .cancel(id: TimerID.self)

      case let .didFinishDownloadingResults(.success(interiorURLs)):
        // Reset timer for current run when new interiors are added
        if interiorURLs.count > state.upload.interiorDesigns.count {
          state.currentStageRunTime = 0
          state.currentStageStartDate = Date()
        }

        // Add only new interiors
        state.upload.interiorDesigns = interiorURLs.map { interiorURL in
          state.upload.interiorDesigns[id: interiorURL] ?? InteriorDesign(imageURL: interiorURL)
        }.sorted { design, design2 in
          design.imageURL.absoluteString < design2.imageURL.absoluteString
        }.identified()

        if interiorURLs.count < UploadResultsScreen.maxImagesToDownload {
          let progress = Double(interiorURLs.count) / Double(UploadResultsScreen.maxImagesToDownload)
          state.upload.status = .downloading(.progress(progress))
        } else {
          state.upload.status = .downloading(.completed)
          return .cancel(id: TimerID.self)
        }

        return .none

      case .refreshCurrentRunTimer:
        state.currentStageRunTime = Date().timeIntervalSince(state.currentStageStartDate)
        return .none

      case .result:
        return .none
      }
    }
    .forEach(\.results, action: /Action.result(id:action:)) {
      ResultDetails()
    }
    .onChange(of: \.results) { results, state, _ in
      log.debug("Updating upload interiors")
      state.upload.interiorDesigns = results.map(\.interiorDesign).identified()
      return .none
    }
    .onChange(of: \.upload) { upload, state, _ in
      log.debug("Updating upload")
      uploadsStorage.updateUpload(upload.upload)
      state.results = upload.interiorDesigns.map { interiorDesign in
        state.results[id: interiorDesign.id] ?? ResultDetails.State(interiorDesign: interiorDesign, originalImageURL: upload.uploadImageURL)
      }.identified()
      return .none
    }
  }

  private func downloadImages(state: inout State) -> EffectTask<Action> {
    state.upload.status = .downloading(.progress(0))

    return .run { [state] send in
      for await _ in self.clock.timer(interval: .seconds(1)) {
        await send(.didFinishDownloadingResults(TaskResult {
          try await backendClient.getImageURLs(state.id)
        }))
      }
    }
    .merge(with: .run { send in
      for await _ in self.clock.timer(interval: .seconds(0.1)) {
        await send(.refreshCurrentRunTimer)
      }
    })
    .cancellable(id: TimerID(), cancelInFlight: true)
  }

  private func uploadImage(state: State) -> EffectTask<Action> {
    .run { @MainActor [id = state.id] send in
      enum UploadError: Error {
        case cantGetData
      }

      let image = try uploadsStorage.getUploadImage(id)

      guard let data = image.jpegData(compressionQuality: 0.7) else {
        send(.updateUploadProgress(.failed(UploadError.cantGetData.equatable)))
        return
      }

      for await progress in backendClient.uploadImage(id, data) {
        send(.updateUploadProgress(progress))
      }

      send(.updateUploadProgress(.completed))
    }
  }
}

// MARK: - UploadResultsScreenView

public struct UploadResultsScreenView: View {
  @ObserveInjection var inject
  @Namespace private var animation

  let store: StoreOf<UploadResultsScreen>

  public init(store: StoreOf<UploadResultsScreen>) {
    self.store = store
  }

  public var body: some View {
    WithViewStore(store, observe: { $0 }) { viewStore in
      ZStack {
        Color.DS.gradient10Animated.ignoresSafeArea()

        if viewStore.results.isEmpty {
          emptyStateView(viewStore)
        } else {
          ScrollView(showsIndicators: false) {
            LazyVGrid(columns: [GridItem(.flexible(), spacing: 16), GridItem(.flexible(), spacing: 16)], spacing: 16) {
              ForEach(viewStore.results) { result in
                cellView(result, viewStore)
              }

              if viewStore.upload.status.isDownloading {
                imagePlaceholder(viewStore)
                  .matchedGeometryEffect(id: "loading", in: animation)
              }
            }
            .padding(.grid(4))
          }
        }
      }
      .animation(.easeInOut(duration: 0.3), value: viewStore.results)
      .task { await viewStore.send(.task).finish() }

      .sheet(
        isPresented: Binding {
          viewStore.selectedId != nil
        } set: {
          if !$0 { viewStore.send(.setSheet(selectedId: nil)) }
        }
      ) {
        if let id = viewStore.selectedId {
          IfLetStore(store.scope(state: { $0.results[id: id] }, action: { .result(id: id, action: $0) })) { resultStore in
            ResultDetailsView(store: resultStore)
          } else: {
            Text("Something went wrong")
              .font(.DS.titleM)
              .foregroundColor(.DS.colorful01)
          }
        }

        // TabView(selection: viewStore.binding(
        //   get: { $0.selectedId ?? URL(filePath: "") },
        //   send: { .setSheet(selectedId: $0) }
        // )) {
        //   ForEach(viewStore.results) { result in
        //     IfLetStore(store.scope(state: { $0.results[id: result.id] }, action: { .result(id: result.id, action: $0) })) { resultStore in
        //       ResultDetailsView(store: resultStore)
        //     } else: {
        //       Text("Something went wrong")
        //         .font(.DS.titleM)
        //         .foregroundColor(.DS.colorful01)
        //     }
        //     .tag(result.id)
        //   }
        // }
        // .tabViewStyle(PageTabViewStyle())
        // .introspectPagedTabView { view, view2 in
        //   log.debug("Introspect \(view) \(view2)")
        //   view.clipsToBounds = false
        //   view2.clipsToBounds = false
        //   view2.isDirectionalLockEnabled = true
        // }
      }
    }
    .enableInjection()
  }

  func imagePlaceholder(_ viewStore: ViewStoreOf<UploadResultsScreen>) -> some View {
    VStack(spacing: .grid(2)) {
      ProgressView()

      loadingStatusText(viewStore)
    }
    .padding(.vertical, .grid(6))
  }

  func loadingStatusText(_ viewStore: ViewStoreOf<UploadResultsScreen>) -> some View {
    ZStack {
      if let uploadProgress = viewStore.upload.status.uploadingProgress {
        Text("Uploading \(Int(uploadProgress * 100))%")
      } else {
        let currentStageRunTime = String(format: "%.1f", viewStore.currentStageRunTime)
        HStack(spacing: .grid(1)) {
          Text("Generating")
          Text("\(currentStageRunTime)s").monospaced()
        }
      }
    }
  }

  @MainActor
  func cellView(_ result: ResultDetails.State, _ viewStore: ViewStoreOf<UploadResultsScreen>) -> some View {
    LazyImage(url: result.imageURL) { state in
      if let image = state.image {
        image
          .resizable()
          .scaledToFit()
      } else {
        Color.clear.aspectRatio(1, contentMode: .fit)
          .overlay(ProgressView())
          .overlay {
            RoundedRectangle(cornerRadius: 12)
              .stroke(Color.DS.background02, lineWidth: 1)
          }
      }
    }
    .cornerRadius(12)
    .onTapGesture {
      viewStore.send(.setSheet(selectedId: result.id))
    }
  }

  func emptyStateView(_ viewStore: ViewStoreOf<UploadResultsScreen>) -> some View {
    ZStack {
      if viewStore.upload.status.isUploading || viewStore.upload.status.isDownloading {
        LottieView(state: LUStateData(
          type: .filepath(Files.App.Resources.Lottie.loadingJson.path),
          speed: 1.0,
          loopMode: .loop
        ))
        .padding(.horizontal, .grid(8))
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        .ignoresSafeArea()
      } else if let error = viewStore.upload.status.error {
        VStack(spacing: .grid(2)) {
          Image(systemName: "exclamationmark.triangle.fill")

          Text("Something went wrong")
            .font(.DS.titleL)
            .foregroundColor(.DS.colorful01)

          Text(error.localizedDescription)

          Button { viewStore.send(.task) } label: { Image(systemName: "arrow.clockwise") }
            .buttonStyle(PrimaryButtonStyle())
        }
        .font(.DS.titleM)
        .foregroundColor(.DS.colorful07)
      }

      loadingStatusText(viewStore)
        .matchedGeometryEffect(id: "loading", in: animation)
        .padding(.bottom, .grid(4))
        .padding(.horizontal, .grid(4))
        .frame(maxHeight: .infinity, alignment: .bottom)
    }
  }
}

#if DEBUG
  struct UploadResultsScreenView_Previews: PreviewProvider {
    static var previews: some View {
      NavigationView {
        UploadResultsScreenView(
          store: Store(
            initialState: UploadResultsScreen.State(upload: .fixture(id: "2")),
            reducer: UploadResultsScreen()
          )
        )
      }
    }
  }
#endif
