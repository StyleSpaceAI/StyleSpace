import AppDevUtils
import Foundation

enum BackendEndpoint {
  static let baseUrl = URL(string: Secrets.backendBaseURL)!
  static let serpApiBaseUrl = URL(staticString: "https://serpapi.com")

  case uploadImage(id: String)
  case getImageList(id: String)
  case getLensResult(imageURL: URL)

  var url: URL {
    switch self {
    case let .uploadImage(id), let .getImageList(id):
      return BackendEndpoint.baseUrl.appendingPathComponent("/design/\(id)")
    case let .getLensResult(imageURL):
      let engine = "google_lens"
      let apiKey = Secrets.serpApiKey
      guard var components = URLComponents(string: BackendEndpoint.serpApiBaseUrl.absoluteString) else {
        log.error("Could not create URLComponents from \(BackendEndpoint.serpApiBaseUrl)")
        return BackendEndpoint.serpApiBaseUrl
      }
      components.path.append("/search")
      components.queryItems = [
        URLQueryItem(name: "engine", value: engine),
        URLQueryItem(name: "api_key", value: apiKey),
        URLQueryItem(name: "url", value: imageURL.absoluteString),
      ]
      guard let url = components.url else {
        log.error("Could not create URL from \(components)")
        return BackendEndpoint.serpApiBaseUrl
      }
      return url
    }
  }

  var method: String {
    switch self {
    case .uploadImage:
      return "POST"
    case .getImageList, .getLensResult:
      return "GET"
    }
  }

  var request: URLRequest {
    var request = URLRequest(url: url)
    request.httpMethod = method
    return request
  }
}
