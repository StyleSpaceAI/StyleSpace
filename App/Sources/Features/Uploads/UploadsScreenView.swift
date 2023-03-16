import AppDevUtils
import ComposableArchitecture
import Foundation
import Inject
import NukeUI
import SwiftUI

// MARK: - UploadsScreen

public struct UploadsScreen: ReducerProtocol {
  public struct State: Equatable {
    var uploads = IdentifiedArrayOf<UploadContainer>()
  }

  public enum Action: Equatable {
    case didAppear
    case didTapUploadResults(id: String)
    case takePictureButtonTapped
  }

  @Dependency(\.uploadsStorage) var uploadsStorage: UploadsStorageClient

  public var body: some ReducerProtocol<State, Action> {
    Reduce<State, Action> { state, action in
      switch action {
      case .didAppear:
        do {
          state.uploads = try uploadsStorage.getUploads()
        } catch {
          log.error(error)
        }
        return .none

      case .didTapUploadResults:
        return .none

      case .takePictureButtonTapped:
        return .none
      }
    }
  }
}

// MARK: - UploadsScreenView

@MainActor
public struct UploadsScreenView: View {
  @ObserveInjection var inject

  let store: Store<UploadsScreen.State, UploadsScreen.Action>

  public init(store: Store<UploadsScreen.State, UploadsScreen.Action>) {
    self.store = store
  }

  public var body: some View {
    WithViewStore(store) { viewStore in
      ZStack {
        Color.DS.gradient10Animated.ignoresSafeArea()

        if viewStore.uploads.isEmpty {
          ZStack(alignment: .center) {
            Text("The gallery is empty.")
              .fontWeight(.semibold)
              .font(.DS.titleM)
              .padding(.bottom, 50)

            Button("Take your first picture") {
              viewStore.send(.takePictureButtonTapped)
            }.buttonStyle(PrimaryButtonStyle())
              .frame(maxHeight: .infinity, alignment: .bottom)
              .padding()
          }
        } else {
          ScrollView(showsIndicators: false) {
            LazyVStack(spacing: .grid(4)) {
              ForEach(viewStore.uploads) { upload in
                Button {
                  viewStore.send(.didTapUploadResults(id: upload.id))
                } label: {
                  rowView(upload: upload)
                }
                .buttonStyle(UploadsRowButtonStyle())
              }
            }
            .padding(.grid(4))
          }
        }
      }
      .onAppear { viewStore.send(.didAppear) }
    }
    .enableInjection()
  }

  private func rowView(upload: UploadContainer) -> some View {
    VStack(spacing: .grid(1)) {
      Text(upload.creationDate.formatted)
        .font(.DS.captionM)
        .foregroundColor(.DS.stateDeactive)
        .padding(.horizontal, .grid(2))
        .frame(maxWidth: .infinity, alignment: .leading)

      HStack(spacing: .grid(2)) {
        squareImage(url: upload.uploadImageURL)

        VStack(spacing: .grid(2)) {
          squareImage(url: upload.interiorDesigns[safe: 0]?.imageURL)
          squareImage(url: upload.interiorDesigns[safe: 1]?.imageURL)
        }

        VStack(spacing: .grid(2)) {
          squareImage(url: upload.interiorDesigns[safe: 2]?.imageURL)
          squareImage(url: upload.interiorDesigns[safe: 3]?.imageURL).overlay {
            if upload.interiorDesigns.count > 4 {
              Text("+\(upload.interiorDesigns.count - 4)")
                .font(.DS.titleS)
                .foregroundColor(.DS.colorWhite)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(.thinMaterial.opacity(0.7),
                            in: RoundedRectangle(cornerRadius: .grid(4)))
                .continuousCornerRadius(.grid(4))
            }
          }
        }
      }
      .frame(maxWidth: .infinity, alignment: .leading)
      .frame(height: (UIScreen.main.bounds.width - .grid(14)) / 2)
      .padding(.grid(2))
      .background(Color.DS.background02)
      .continuousCornerRadius(.grid(4))
    }
  }

  private func squareImage(url: URL?) -> some View {
    Color.clear
      .aspectRatio(1, contentMode: .fit)
      .background {
        LazyImage(url: url) { state in
          if let image = state.image {
            image
              .resizable()
              .scaledToFill()
          } else {
            ProgressView()
          }
        }
      }
      .continuousCornerRadius(.grid(4))
      .clipped()
  }
}

// MARK: - UploadsRowButtonStyle

struct UploadsRowButtonStyle: ButtonStyle {
  func makeBody(configuration: Configuration) -> some View {
    configuration.label
      .scaleEffect(configuration.isPressed ? 0.95 : 1)
  }
}

private extension Date {
  private static let formatter = DateFormatter().then {
    $0.dateStyle = .medium
    $0.timeStyle = .medium
  }

  var formatted: String {
    Date.formatter.string(from: self)
  }
}

#if DEBUG
  struct UploadsScreenView_Previews: PreviewProvider {
    static var previews: some View {
      NavigationView {
        UploadsScreenView(
          store: Store(
            initialState: UploadsScreen.State(),
            reducer: UploadsScreen()
          )
        )
      }
    }
  }
#endif
