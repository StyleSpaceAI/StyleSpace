import Foundation

// MARK: - Progress

public enum Progress: Hashable, Codable {
  case notStarted
  case progress(Double)
  case completed
  case failed(EquatableErrorWrapper)
}

extension Progress {
  var isInProgress: Bool {
    if case .progress = self {
      return true
    }
    return false
  }

  var progressValue: Double? {
    if case let .progress(value) = self {
      return value
    }
    return nil
  }

  var isNotStarted: Bool {
    if case .notStarted = self {
      return true
    }
    return false
  }

  var failedError: EquatableErrorWrapper? {
    if case let .failed(error) = self {
      return error
    }
    return nil
  }
}
