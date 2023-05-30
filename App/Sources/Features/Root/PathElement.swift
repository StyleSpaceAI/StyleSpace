import Foundation

// MARK: - PathElement

struct PathElement: Hashable, Identifiable {
  var id = UUID()
  var route: Route
}

extension PathElement {
  static func flowSelection(state: FlowSelectionScreen.State) -> PathElement {
    PathElement(route: .flowSelection(state: state))
  }

  static func camera() -> PathElement {
    PathElement(route: .camera)
  }

  static func uploads() -> PathElement {
    PathElement(route: .uploads)
  }

  static func uploadResults(id: String, state: UploadResultsScreen.State) -> PathElement {
    PathElement(route: .uploadResults(id: id, state: state))
  }

  static func settings() -> PathElement {
    PathElement(route: .settings)
  }
}
