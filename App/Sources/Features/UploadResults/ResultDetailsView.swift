import AppDevUtils
import ComposableArchitecture
import Dependencies
import IdentifiedCollections
import Inject
import Introspect
import NukeUI
import SwiftUI

// MARK: - ResultDetails

public struct ResultDetails: ReducerProtocol {
  public struct State: Hashable, Identifiable {
    public var id: URL { interiorDesign.id }

    @BindingState var alert: AlertState<AlertAction>?

    var interiorDesign: InteriorDesign
    var originalImageURL: URL
    @BindingState var isShowingSlider = false
    var isLoadingProducts = false

    var imageURL: URL { interiorDesign.imageURL }
  }

  public enum Action: BindableAction, Equatable {
    case binding(BindingAction<State>)
    case onDisappear
    case searchProductsButtonTapped
    case didFinishSearchingProducts(TaskResult<GoogleLensResult>)
    case alert(AlertAction)
  }

  @Dependency(\.backend) var backendClient: BackendClient

  public var body: some ReducerProtocol<State, Action> {
    BindingReducer()

    Reduce { state, action in
      switch action {
      case .binding:
        return .none

      case .onDisappear:
        state.isShowingSlider = false
        state.alert = nil
        return .none

      case .searchProductsButtonTapped:
        state.isLoadingProducts = true
        state.alert = nil
        return .task { [url = state.imageURL] in
          await .didFinishSearchingProducts(TaskResult { try await backendClient.getLensResult(url) })
        }.animation()

      case let .didFinishSearchingProducts(.success(lensResult)):
        state.isLoadingProducts = false
        state.interiorDesign.lensResult = lensResult
        return .none

      case let .didFinishSearchingProducts(.failure(error)):
        log.error("Failed to get lens result: \(error)")

        state.isLoadingProducts = false
        state.alert = .init(
          title: TextState("Failed to get products"),
          message: TextState("Please try again later"),
          dismissButton: .default(TextState("OK"))
        )
        return .none

      case .alert:
        state.alert = nil
        return .none
      }
    }
  }
}

// MARK: - ResultDetailsView

@MainActor
public struct ResultDetailsView: View {
  @ObserveInjection var inject
  @Namespace var namespace

  let store: StoreOf<ResultDetails>

  public init(store: StoreOf<ResultDetails>) {
    self.store = store
  }

  public var body: some View {
    WithViewStore(store, observe: { $0 }) { viewStore in
      ScrollView(.vertical, showsIndicators: false) {
        LazyVStack(spacing: .grid(2)) {
          if viewStore.isShowingSlider {
            ImageSlider(leftImageURL: viewStore.imageURL, rightImageURL: viewStore.originalImageURL)
          } else {
            LazyImage(url: viewStore.imageURL) { state in
              if let image = state.image {
                image.resizable().scaledToFit()
              } else {
                Color.clear.overlay(ProgressView())
              }
            }
          }

          HStack(spacing: .grid(2)) {
            Toggle("Compare with original", isOn: viewStore.binding(\.$isShowingSlider))
              .toggleStyle(SwitchToggleStyle(tint: .DS.colorSecondary))
              .labelsHidden()
            Text("Compare")
              .font(.DS.titleS)
            Spacer()
            ShareButton(imageURL: viewStore.imageURL)
          }
          .padding(.horizontal, .grid(4))

          if let lensResult = viewStore.interiorDesign.lensResult {
            productResults(lensResult)
              .padding(.horizontal, .grid(4))
          } else {
            ZStack {
              if viewStore.isLoadingProducts {
                ProgressView()
                  .matchedGeometryEffect(id: "lens", in: namespace)
              } else {
                Button("Search products") {
                  viewStore.send(.searchProductsButtonTapped)
                }
                .buttonStyle(SecondaryButtonStyle())
                .matchedGeometryEffect(id: "lens", in: namespace)
              }
            }
            .padding(.top, .grid(4))

            if let alert = viewStore.alert {
              VStack {
                Text(alert.title)
                if let message = alert.message {
                  Text(message)
                }
              }
              .font(.DS.bodyS)
              .foregroundColor(.DS.colorful02)
            }
          }

          Spacer()
        }
        .animation(.easeInOut(duration: 0.3), value: viewStore.isLoadingProducts)
        .animation(.easeInOut(duration: 0.3), value: viewStore.interiorDesign.lensResult)
      }
      .onDisappear {
        viewStore.send(.onDisappear)
      }
    }
    .enableInjection()
  }

  func productResults(_ lensResult: GoogleLensResult) -> some View {
    VStack(spacing: .grid(2)) {
      ForEach(lensResult.visualMatches, id: \.self) { product in
        HStack(spacing: .grid(2)) {
          Color.clear
            .aspectRatio(1, contentMode: .fit)
            .background {
              LazyImage(url: URL(string: product.thumbnail)) { state in
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

          Text(product.title)
            .font(.DS.bodyM)
            .foregroundColor(.DS.colorWhite)
            .padding(.horizontal, .grid(4))
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(height: 100)
        .padding(.grid(2))
        .background(Color.DS.background02)
        .continuousCornerRadius(.grid(4))
        .onTapGesture {
          if let url = URL(string: product.link) {
            UIApplication.shared.open(url)
          }
        }
      }
    }
  }
}

// MARK: - ImageSlider

private struct ImageSlider: View {
  @State private var dividingWidth: CGFloat = 0
  @State private var aspectRatio: CGFloat = 3 / 4
  @State private var sliderSize: CGSize = .init(width: 100, height: 100)
  @State private var isFirstAppear = true

  var leftImageURL: URL
  var rightImageURL: URL

  var body: some View {
    ZStack {
      HStack {
        let imageWidth = dividingWidth

        LazyImage(url: leftImageURL) { state in
          if let image = state.image, let imageContainer = state.imageContainer {
            image
              .resizable()
              .scaledToFit()
              .onAppear { aspectRatio = imageContainer.image.size.width / imageContainer.image.size.height }
          } else {
            Color.clear.overlay(ProgressView())
          }
        }
        .frame(width: sliderSize.width, height: sliderSize.width / aspectRatio)
        .fixedSize()
        .frame(width: imageWidth, alignment: .leading)
        .clipped()

        Spacer()
          .frame(width: sliderSize.width - imageWidth)
      }

      HStack {
        let imageWidth = sliderSize.width - dividingWidth

        Spacer()
          .frame(width: sliderSize.width - imageWidth)

        LazyImage(url: rightImageURL) { state in
          if let image = state.image {
            image.resizable().scaledToFill()
          } else {
            Color.clear.overlay(ProgressView())
          }
        }
        .frame(width: sliderSize.width, height: sliderSize.width / aspectRatio)
        .fixedSize()
        .frame(width: imageWidth, alignment: .trailing)
        .clipped()
      }
    }
    .overlay(SlideBar(slideLocation: $dividingWidth, range: 0 ... sliderSize.width))
    .frame(maxWidth: .infinity)
    .readSize {
      sliderSize = $0
      if isFirstAppear {
        dividingWidth = sliderSize.width / 2
        isFirstAppear = false
      }
    }
  }
}

// MARK: - SlideBar

private struct SlideBar: View {
  @Binding var slideLocation: CGFloat
  let range: ClosedRange<CGFloat>
  @State private var dragStartValue: CGFloat? = nil

  private var rangeMiddle: CGFloat {
    ((range.upperBound - range.lowerBound) / 2) + range.lowerBound
  }

  private var dragGesture: some Gesture {
    DragGesture()
      .onChanged { value in
        if dragStartValue == nil {
          dragStartValue = slideLocation
        }

        slideLocation = max(range.lowerBound,
                            min(range.upperBound, dragStartValue! + value.translation.width))
      }
      .onEnded { _ in
        dragStartValue = nil
      }
  }

  var body: some View {
    ZStack {
      VerticalLine()
        .stroke(lineWidth: 2)
        .shadow(radius: 3.0)

      SlideControlShape()
        .stroke()
        .frame(width: 10, height: 20)
        .shadow(radius: 3.0)
        .background(SlideControlShape().fill(.background))
    }
    .offset(x: slideLocation - rangeMiddle)
    .gesture(dragGesture)
  }
}

// MARK: - SlideControlShape

private struct SlideControlShape: Shape {
  func path(in rect: CGRect) -> Path {
    var path = Path()

    path.addRoundedRect(in: rect, cornerSize: CGSize(width: 2.0, height: 3.0))

    let widthFourth = rect.width / 4
    let heightSixth = rect.height / 6

    path.move(to: CGPoint(x: widthFourth, y: heightSixth))
    path.addLine(to: CGPoint(x: widthFourth, y: 5 * heightSixth))

    path.move(to: CGPoint(x: 2 * widthFourth, y: heightSixth))
    path.addLine(to: CGPoint(x: 2 * widthFourth, y: 5 * heightSixth))

    path.move(to: CGPoint(x: 3 * widthFourth, y: heightSixth))
    path.addLine(to: CGPoint(x: 3 * widthFourth, y: 5 * heightSixth))

    return path
  }
}

// MARK: - VerticalLine

private struct VerticalLine: Shape {
  func path(in rect: CGRect) -> Path {
    var path = Path()

    path.move(to: CGPoint(x: rect.width / 2, y: 0))
    path.addLine(to: CGPoint(x: rect.width / 2, y: rect.height))

    return path
  }
}

#if DEBUG
  struct ResultDetailsView_Previews: PreviewProvider {
    static var previews: some View {
      NavigationView {
        ResultDetailsView(
          store: Store(
            initialState: ResultDetails.State(interiorDesign: .fixture1, originalImageURL: .fixtureImageURL1),
            reducer: ResultDetails()
          )
        )
      }
    }
  }
#endif
