import Foundation

extension String {
  var encoded: String {
    addingPercentEncoding(withAllowedCharacters: .urlHostAllowed) ?? self
  }
}
