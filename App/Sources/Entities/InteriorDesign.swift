import Foundation

// MARK: - InteriorDesign

struct InteriorDesign: Codable, Hashable, Identifiable {
  var id: URL { imageURL }
  var imageURL: URL
  var lensResult: GoogleLensResult? = nil
  var isFavorite: Bool = false
}

#if DEBUG
  extension InteriorDesign {
    static let fixture1 = InteriorDesign(
      imageURL: .fixtureImageURL1
    )

    static let fixture2 = InteriorDesign(
      imageURL: .fixtureImageURL2
    )
  }
#endif
