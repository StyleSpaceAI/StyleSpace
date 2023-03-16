import Foundation

public struct GoogleLensResult: Hashable, Codable {
  let visualMatches: [VisualMatch]

  enum CodingKeys: String, CodingKey {
    case visualMatches = "visual_matches"
  }

  struct TextResult: Hashable, Codable {
    let query: String
    let link: String
    let serpapiLink: String

    enum CodingKeys: String, CodingKey {
      case query
      case link
      case serpapiLink = "serpapi_link"
    }
  }

  struct RelatedContent: Hashable, Codable {
    let query: String
    let link: String
    let serpapiLink: String

    enum CodingKeys: String, CodingKey {
      case query
      case link
      case serpapiLink = "serpapi_link"
    }
  }

  struct VisualMatch: Hashable, Codable {
    let position: Int
    let title: String
    let link: String
    let source: String
    let sourceIcon: String
    let thumbnail: String

    enum CodingKeys: String, CodingKey {
      case position
      case title
      case link
      case source
      case sourceIcon = "source_icon"
      case thumbnail
    }
  }
}

