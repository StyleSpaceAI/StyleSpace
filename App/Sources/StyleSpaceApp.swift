import ComposableArchitecture
import SwiftUI

@main
struct StyleSpaceApp: App {
  var body: some Scene {
    WindowGroup {
      RootView(
        store: Store(
          initialState: RootStateStorage.readState(),
          reducer: Root()
        )
      )
    }
  }
}
