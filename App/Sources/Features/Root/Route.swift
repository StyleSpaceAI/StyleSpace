import Foundation

// MARK: - Route

enum Route: Hashable {
  case flowSelection(state: FlowSelectionScreen.State)
  case camera
  case uploads
  case uploadResults(id: String, state: UploadResultsScreen.State)
  case settings
}

extension Route {
  var flowSelectionState: FlowSelectionScreen.State? {
    guard case let .flowSelection(state) = self else { return nil }
    return state
  }

  var uploadResultsState: (id: String, state: UploadResultsScreen.State)? {
    guard case let .uploadResults(id, state) = self else { return nil }
    return (id, state)
  }
}
