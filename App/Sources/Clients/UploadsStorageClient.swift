import AppDevUtils
import ComposableArchitecture
import Dependencies
import Foundation
import IdentifiedCollections
import class UIKit.UIImage

// MARK: - UploadsStorageError

enum UploadsStorageError: Error {
  case cantGetImageData
}

// MARK: - UploadsStorageClient

struct UploadsStorageClient {
  var saveImage: @Sendable (_ image: UIImage, _ id: String) throws -> Void
  var getImageURLs: @Sendable () throws -> IdentifiedArrayOf<Identified<String, URL>>
  var getUploadImage: @Sendable (_ id: String) throws -> UIImage

  var getUploads: @Sendable () throws -> IdentifiedArrayOf<UploadContainer>
  var listenForUploads: @Sendable () -> AsyncStream<[Upload]>
  var updateUploads: @Sendable ([Upload]) -> Void
  var addUpload: @Sendable (Upload) throws -> Void
  var getUploadContainer: @Sendable (_ id: String) throws -> UploadContainer?
  var updateUpload: @Sendable (_ upload: Upload) -> Void
}

extension DependencyValues {
  var uploadsStorage: UploadsStorageClient {
    get { self[UploadsStorageClient.self] }
    set { self[UploadsStorageClient.self] = newValue }
  }
}

// MARK: - UploadsStorageClient + DependencyKey

extension UploadsStorageClient: DependencyKey {
  static let liveValue: UploadsStorageClient = {
    @Sendable
    func getStorageDirectory() throws -> URL {
      let documentsDirectory = try FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
      let storageDirectory = documentsDirectory.appendingPathComponent("uploads", isDirectory: true)
      return storageDirectory
    }

    let documentsDirectory: URL
    do {
      documentsDirectory = try FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
    } catch {
      log.error(error)
      documentsDirectory = FileManager.default.temporaryDirectory
    }
    let jsonFileURL = documentsDirectory.appendingPathComponent("uploads.json")
    let uploadsSubject = CodableValueSubject<[Upload]>(fileURL: jsonFileURL)

    return UploadsStorageClient(
      saveImage: { image, id in
        guard let data = image.jpegData(compressionQuality: 0.8) else {
          throw UploadsStorageError.cantGetImageData
        }

        let storageDirectory = try getStorageDirectory()
        if FileManager.default.fileExists(atPath: storageDirectory.path) == false {
          try FileManager.default.createDirectory(at: storageDirectory, withIntermediateDirectories: true, attributes: nil)
        }
        let fileName = "\(id).jpg"
        let fileURL = storageDirectory.appendingPathComponent(fileName)

        try data.write(to: fileURL, options: .atomic)
      },
      getImageURLs: {
        let storageDirectory = try getStorageDirectory()
        let urls: [Identified<String, URL>] = uploadsSubject.value?
          .map {
            let fileName = "\($0.id).jpg"
            let url = storageDirectory.appendingPathComponent(fileName)
            return Identified(url, id: $0.id)
          }
          ?? []
        return urls.identified()
      },
      getUploadImage: {
        let storageDirectory = try getStorageDirectory()
        let fileName = "\($0).jpg"
        let fileURL = storageDirectory.appendingPathComponent(fileName)
        guard let data = try? Data(contentsOf: fileURL) else {
          throw UploadsStorageError.cantGetImageData
        }
        guard let image = UIImage(data: data) else {
          throw UploadsStorageError.cantGetImageData
        }
        return image
      },
      getUploads: {
        let storageDirectory = try getStorageDirectory()

        return (uploadsSubject.value ?? []).map { upload in
          let fileName = "\(upload.id).jpg"
          let fileURL = storageDirectory.appendingPathComponent(fileName)
          return UploadContainer(upload: upload, uploadImageURL: fileURL)
        }
        .sorted { item, item2 in
          item.upload.creationDate > item2.upload.creationDate
        }
        .identified()
      },
      listenForUploads: {
        uploadsSubject.assertNoFailure().asAsyncStream()
      },
      updateUploads: { uploads in
        uploadsSubject.send(uploads)
      },
      addUpload: { upload in
        var uploads = uploadsSubject.value ?? []
        uploads.append(upload)
        uploadsSubject.send(uploads)
      },
      getUploadContainer: { id in
        guard let upload = uploadsSubject.value?.first(where: { $0.id == id }) else {
          return nil
        }

        let storageDirectory = try getStorageDirectory()
        let fileName = "\(upload.id).jpg"
        let fileURL = storageDirectory.appendingPathComponent(fileName)
        return UploadContainer(upload: upload, uploadImageURL: fileURL)
      },
      updateUpload: { upload in
        var uploads = uploadsSubject.value ?? []
        if let index = uploads.firstIndex(where: { $0.id == upload.id }) {
          uploads[index] = upload
        } else {
          log.error("Upload with id \(upload.id) not found")
        }
        uploadsSubject.send(uploads)
      }
    )
  }()
}

#if DEBUG

  extension URL {
    static let fixtureImageURL1 = URL(
      staticString: "https://images.unsplash.com/photo-1674289145833-b3ec3cd37b34?ixlib=rb-4.0.3&ixid=MnwxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8&auto=format&fit=crop&w=1035&q=80"
    )

    static let fixtureImageURL2 = URL(
      staticString: "https://images.unsplash.com/photo-1678226119721-09c8c9e862d1?ixlib=rb-4.0.3&ixid=MnwxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8&auto=format&fit=crop&w=987&q=80"
    )
  }

  extension UploadsStorageClient {
    static let previewValue: UploadsStorageClient = .init(
      saveImage: { _, _ in },
      getImageURLs: {
        [
          Identified(.fixtureImageURL1, id: "1"),
          Identified(.fixtureImageURL2, id: "2"),
        ].identified()
      },
      getUploadImage: { _ in UIImage(systemName: "photo")! },
      getUploads: {
        [.fixture(id: "1"), .fixture(id: "2")].map { upload in
          UploadContainer(upload: upload, uploadImageURL: .fixtureImageURL1)
        }.identified()
      },
      listenForUploads: {
        AsyncStream {
          $0.yield([.fixture(id: "1"), .fixture(id: "2")])
        }
      },
      updateUploads: { _ in },
      addUpload: { _ in },
      getUploadContainer: { _ in .fixture(id: "1") },
      updateUpload: { _ in }
    )
  }
#endif
