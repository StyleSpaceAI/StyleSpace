import UIKit

extension UIImage {
  func rotated(to orientation: Orientation) -> UIImage {
    guard let cgImage else {
      return self
    }

    return UIImage(
      cgImage: cgImage,
      scale: scale,
      orientation: orientation
    )
  }
}
