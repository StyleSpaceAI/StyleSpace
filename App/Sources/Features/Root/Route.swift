import Foundation

// MARK: - Route

enum Route: Hashable {
  case camera
  case uploads
  case uploadResults(id: String, state: UploadResultsScreen.State)
  case settings
}

extension Route {
  var uploadResultsState: (id: String, state: UploadResultsScreen.State)? {
    guard case let .uploadResults(id, state) = self else { return nil }
    return (id, state)
  }
}
