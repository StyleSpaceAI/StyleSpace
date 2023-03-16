import AppDevUtils
import ComposableArchitecture
import Inject
import SwiftUI

// MARK: - HomeScreen

public struct HomeScreen: ReducerProtocol {
  public struct State: Equatable, Codable {}

  public enum Action: Equatable {
    case takePictureButtonTapped
    case galleryButtonTapped
    case settingsButtonTapped
  }

  public var body: some ReducerProtocol<State, Action> {
    Reduce<State, Action> { _, action in
      switch action {
      case .takePictureButtonTapped:
        return .none
      case .galleryButtonTapped:
        return .none
      case .settingsButtonTapped:
        return .none
      }
    }
  }
}

// MARK: - HomeScreenView

public struct HomeScreenView: View {
  @ObserveInjection var inject
  @State var didFirstAppear = false

  let store: StoreOf<HomeScreen>

  public init(store: StoreOf<HomeScreen>) {
    self.store = store
  }

  public var body: some View {
    WithViewStore(self.store, observe: { $0 }) { viewStore in
      ZStack {
        Color.DS.gradient10Animated.ignoresSafeArea()

        StyleSpaceAsset.homeBack.swiftUIImage
          .resizable()
          .scaledToFit()
          .mask {
            LinearGradient(
              gradient: Gradient(stops: [
                Gradient.Stop(color: .clear, location: 0),
                Gradient.Stop(color: .black, location: 0.5),
                Gradient.Stop(color: .clear, location: 1),
              ]),
              startPoint: .top,
              endPoint: .bottom
            )
          }
          .ignoresSafeArea()
          .frame(maxHeight: .infinity, alignment: .top)
          .opacity(didFirstAppear ? 1 : 0)
          .offset(y: didFirstAppear ? 0 : -50)
          .animation(.default.speed(0.2).delay(0.5), value: didFirstAppear)

        ZStack {
          Button {
            viewStore.send(.settingsButtonTapped)
          } label: {
            Image(systemName: "gearshape.fill")
              .resizable()
              .foregroundColor(.DS.colorSecondary)
              .frame(width: 25, height: 25)
          }
          .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
          .padding(.horizontal, 32)
          .padding(.vertical, 16)
          .opacity(didFirstAppear ? 1 : 0)
          .animation(.easeIn.speed(0.2).delay(0.9), value: didFirstAppear)

          VStack(alignment: .leading, spacing: 32) {
            VStack(alignment: .leading, spacing: 8) {
              HStack(spacing: 8) {
                Text("Style Space")
                  .fontWeight(.bold)

                Text("🎨")
              }
              .font(.subheadline)
              .lineSpacing(24)

              Text("Let's create a new interior for your room.")
                .fontWeight(.semibold)
                .font(.largeTitle)
            }
            .offset(y: didFirstAppear ? 0 : -100)
            .opacity(didFirstAppear ? 1 : 0)
            .animation(.gentleBounce().speed(0.2).delay(0.9), value: didFirstAppear)

            VStack(alignment: .leading, spacing: 16) {
              Button("Take a picture") {
                viewStore.send(.takePictureButtonTapped)
              }
              .buttonStyle(PrimaryButtonStyle())

              Button("Gallery") {
                viewStore.send(.galleryButtonTapped)
              }
              .buttonStyle(SecondaryButtonStyle())
            }
            .offset(y: didFirstAppear ? 0 : -100)
            .opacity(didFirstAppear ? 1 : 0)
            .animation(.gentleBounce().speed(0.2).delay(0.7), value: didFirstAppear)
          }
          .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
          .padding(48)
        }
      }
      .onAppear {
        didFirstAppear = true
      }
    }
    .enableInjection()
  }
}

#if DEBUG
  struct HomeScreenView_Previews: PreviewProvider {
    static var previews: some View {
      NavigationView {
        HomeScreenView(
          store: Store(
            initialState: HomeScreen.State(),
            reducer: HomeScreen()
          )
        )
      }
    }
  }
#endif
