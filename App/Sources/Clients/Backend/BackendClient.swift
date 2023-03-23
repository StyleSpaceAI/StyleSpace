import AppDevUtils
import Dependencies
import Foundation

typealias UploadID = String

// MARK: - BackendClient

struct BackendClient {
  var uploadImage: @Sendable (UploadID, Data) -> AsyncStream<Progress>
  var getImageURLs: @Sendable (UploadID) async throws -> [URL]
  var getLensResult: @Sendable (_ imageURL: URL) async throws -> GoogleLensResult
}

extension DependencyValues {
  var backend: BackendClient {
    get { self[BackendClient.self] }
    set { self[BackendClient.self] = newValue }
  }
}

// MARK: - BackendError

enum BackendError: Error {
  case invalidResponse
}

// MARK: - BackendClient + DependencyKey

extension BackendClient: DependencyKey {
  static let liveValue: BackendClient = {
    let configuration = URLSessionConfiguration.default // background(withIdentifier: "app.stylespace.backend")
    let delegate = SessionDelegate()
    let session = URLSession(configuration: configuration, delegate: delegate, delegateQueue: nil)
    let decoder = JSONDecoder()

    @Sendable
    func validateResponse(_ response: URLResponse?) throws {
      guard let response = response as? HTTPURLResponse else {
        throw BackendError.invalidResponse
      }
      guard (200 ... 299).contains(response.statusCode) else {
        throw BackendError.invalidResponse
      }
    }

    return BackendClient(
      uploadImage: { uploadID, data in
        AsyncStream<Progress> { continuation in
          let endpoint = BackendEndpoint.uploadImage(id: uploadID)
          let request = endpoint.request

          let fileURL: URL

          do {
            let cache = try FileManager.default.url(for: .cachesDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
            fileURL = cache.appendingPathComponent("upload.jpg")
            try data.write(to: fileURL)
          } catch {
            continuation.yield(Progress.failed(error.equatable))
            continuation.finish()
            return
          }

          let task = session.uploadTask(with: request, fromFile: fileURL)
          delegate.addUploadTask(task) {
            continuation.yield(Progress.progress($0))
          } onComplete: { result in
            switch result {
            case .success:
              continuation.yield(Progress.completed)
            case let .failure(error):
              continuation.yield(Progress.failed(error.equatable))
            }
            continuation.finish()
          }

          continuation.onTermination = { @Sendable _ in
            struct TerminationError: Error {}
            task.cancel()
          }

          continuation.yield(Progress.progress(0))
          task.resume()
        }
      },

      getImageURLs: { uploadID in
        let endpoint = BackendEndpoint.getImageList(id: uploadID)
        let request = endpoint.request

        let (data, response) = try await URLSession.shared.data(for: request)

        try validateResponse(response)

        let imageList = try decoder.decode([String].self, from: data)
        let imageListURLs = imageList.compactMap { imageURL in
          if let url = URL(string: imageURL) {
            return url
          } else {
            log.error("Invalid URL for image \(imageURL)")
            return nil
          }
        }

        return imageListURLs
      },

      getLensResult: { imageURL in
        let endpoint = BackendEndpoint.getLensResult(imageURL: imageURL)
        let request = endpoint.request

        log.debug(request)

        let (data, response) = try await URLSession.shared.data(for: request)

        log.debug(String(data: data, encoding: .utf8) ?? "No data")

        try validateResponse(response)

        let lensResult = try decoder.decode(GoogleLensResult.self, from: data)

        return lensResult
      }
    )
  }()
}

// MARK: - DownloadTaskContainer

struct DownloadTaskContainer {
  weak var task: URLSessionDownloadTask?
  let onProgressUpdate: (Double) -> Void
  let onComplete: (Result<URL, Error>) -> Void
}

// MARK: - UploadTaskContainer

struct UploadTaskContainer {
  weak var task: URLSessionUploadTask?
  let onProgressUpdate: (Double) -> Void
  let onComplete: (Result<Void, Error>) -> Void
}

// MARK: - SessionDelegate

class SessionDelegate: NSObject, URLSessionDownloadDelegate {
  private var downloadTasks: [DownloadTaskContainer] = []
  private var uploadTasks: [UploadTaskContainer] = []

  func addDownloadTask(
    _ task: URLSessionDownloadTask,
    onProgressUpdate: @escaping (Double) -> Void,
    onComplete: @escaping (Result<URL, Error>) -> Void
  ) {
    downloadTasks.append(DownloadTaskContainer(task: task, onProgressUpdate: onProgressUpdate, onComplete: onComplete))
  }

  func addUploadTask(
    _ task: URLSessionUploadTask,
    onProgressUpdate: @escaping (Double) -> Void,
    onComplete: @escaping (Result<Void, Error>) -> Void
  ) {
    uploadTasks.append(UploadTaskContainer(task: task, onProgressUpdate: onProgressUpdate, onComplete: onComplete))
  }

  func urlSession(_: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
    for taskContainer in downloadTasks where taskContainer.task == downloadTask {
      taskContainer.onComplete(.success(location))
    }
  }

  func urlSession(
    _: URLSession,
    downloadTask: URLSessionDownloadTask,
    didWriteData _: Int64,
    totalBytesWritten: Int64,
    totalBytesExpectedToWrite: Int64
  ) {
    for taskContainer in downloadTasks where taskContainer.task == downloadTask {
      let progress = Double(totalBytesWritten) / Double(totalBytesExpectedToWrite)
      taskContainer.onProgressUpdate(progress)
    }
  }

  func urlSession(_: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
    if let error {
      for taskContainer in downloadTasks where taskContainer.task == task {
        taskContainer.onComplete(.failure(error))
      }
      for taskContainer in uploadTasks where taskContainer.task == task {
        taskContainer.onComplete(.failure(error))
      }
    } else {
      for taskContainer in uploadTasks where taskContainer.task == task {
        taskContainer.onComplete(.success(()))
      }
    }
  }

  func urlSession(
    _: URLSession,
    task: URLSessionTask,
    didSendBodyData _: Int64,
    totalBytesSent: Int64,
    totalBytesExpectedToSend: Int64
  ) {
    for taskContainer in uploadTasks where taskContainer.task == task {
      let progress = Double(totalBytesSent) / Double(totalBytesExpectedToSend)
      taskContainer.onProgressUpdate(progress)
    }
  }
}
