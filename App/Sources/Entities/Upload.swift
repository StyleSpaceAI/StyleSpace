import Foundation
import IdentifiedCollections

// MARK: - UploadContainer

@dynamicMemberLookup
public struct UploadContainer: Codable, Hashable, Identifiable {
  public var id: String { upload.id }

  var upload: Upload
  var uploadImageURL: URL
}

// MARK: - Upload

public struct Upload: Hashable, Codable, Identifiable {
  public enum Status: Hashable, Codable {
    case uploading(Progress)
    case downloading(Progress)
    case completed
  }

  public var id = UUID().uuidString
  var creationDate: Date = .init()
  var status: Status = .uploading(.notStarted)
  var interiorDesigns: IdentifiedArrayOf<InteriorDesign> = []
}

// MARK: - UploadContainer + Dynamic Member Lookup

public extension UploadContainer {
  subscript<Value>(dynamicMember keyPath: KeyPath<Upload, Value>) -> Value {
    self.upload[keyPath: keyPath]
  }

  subscript<Value>(dynamicMember keyPath: WritableKeyPath<Upload, Value>) -> Value {
    get { self.upload[keyPath: keyPath] }
    set { self.upload[keyPath: keyPath] = newValue }
  }
}

// MARK: - Upload.Status + Lenses

public extension Upload.Status {
  var isCompleted: Bool {
    if case .completed = self {
      return true
    }
    return false
  }

  var isUploading: Bool {
    if case .uploading(.progress) = self {
      return true
    }
    return false
  }

  var isDownloading: Bool {
    if case .downloading(.progress) = self {
      return true
    }
    return false
  }

  var uploadingError: EquatableErrorWrapper? {
    if case let .uploading(.failed(error)) = self {
      return error
    }
    return nil
  }

  var downloadingError: EquatableErrorWrapper? {
    if case let .downloading(.failed(error)) = self {
      return error
    }
    return nil
  }

  var error: EquatableErrorWrapper? {
    uploadingError ?? downloadingError
  }

  var uploadingProgress: Double? {
    if case let .uploading(.progress(progress)) = self {
      return progress
    }
    return nil
  }

  var downloadingProgress: Double? {
    if case let .downloading(.progress(progress)) = self {
      return progress
    }
    return nil
  }
}

#if DEBUG
  extension UploadContainer {
    static func fixture(id: String) -> UploadContainer {
      UploadContainer(
        upload: Upload.fixture(id: id),
        uploadImageURL: .fixtureImageURL1
      )
    }
  }

  extension Upload {
    static func fixture(id: String) -> Upload {
      Upload(
        id: id,
        creationDate: .init(),
        status: .completed,
        interiorDesigns: [
          .fixture1, .fixture2,
        ].identified()
      )
    }
  }
#endif
