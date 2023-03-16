import ComposableArchitecture
import PhotosUI
import SwiftUI
import UIKit

// MARK: - CameraScreen

public struct CameraScreen: ReducerProtocol {
  public struct State: Equatable {}

  public enum Action: Equatable {
    case savePhoto(UIImage)
  }

  public var body: some ReducerProtocol<State, Action> {
    Reduce<State, Action> { _, action in
      switch action {
      case .savePhoto:
        return .none
      }
    }
  }
}

// MARK: - CameraScreenView

struct CameraScreenView: View {
  @State private var image: UIImage?

  let store: StoreOf<CameraScreen>

  public init(store: StoreOf<CameraScreen>) {
    self.store = store
  }

  var body: some View {
    WithViewStore(store, observe: { $0 }) { viewStore in
      ZStack {
        if let image {
          VStack(spacing: 16) {
            Image(uiImage: image)
              .resizable()
              .scaledToFit()
              .frame(maxHeight: .infinity)

            HStack(spacing: 0) {
              Button("Retake") {
                self.image = nil
              }.buttonStyle(SecondaryButtonStyle())

              Spacer()

              Button("Save") {
                viewStore.send(.savePhoto(image))
              }.buttonStyle(PrimaryButtonStyle())
            }
            .padding([.leading, .trailing], 24)
          }
          .padding([.top, .bottom], 24)

        } else {
          #if targetEnvironment(simulator)
            Color.DS.colorful01.cornerRadius(24).padding()
            Button("Save") {
//              viewModel.path = [.gallery]
            }.buttonStyle(PrimaryButtonStyle())
          #else
            CameraView { image in
              loadImage(inputImage: image)
            }
          #endif
        }
      }
      .navigationBarItems(trailing:
        PhotosPicker(
          selection: $selectedItem,
          matching: .images,
          photoLibrary: .shared()
        ) {
          Image(systemName: "plus")
        }
        .onChange(of: selectedItem) { newItem in
          Task {
            // Retrieve selected asset in the form of Data
            if let data = try? await newItem?.loadTransferable(type: Data.self) {
              selectedImageData = UIImage(data: data)
            }
          }
        })
      .frame(maxWidth: .infinity, maxHeight: .infinity)
      .screenAnimatedBackground()
      .onChange(of: selectedImageData) { image in
        loadImage(inputImage: image)
      }
    }
  }

  @State private var isPickerPresented = false
  @State private var selectedItem: PhotosPickerItem? = nil
  @State private var selectedImageData: UIImage? = nil

  func loadImage(inputImage: UIImage?) {
    image = inputImage
    // UIImageWriteToSavedPhotosAlbum(inputImage, nil, nil, nil)
  }
}
