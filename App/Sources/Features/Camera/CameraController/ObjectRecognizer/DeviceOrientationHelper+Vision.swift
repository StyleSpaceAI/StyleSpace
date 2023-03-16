import UIKit
import Vision

extension DeviceOrientationHelper.Orientation {
  var asCGImagePropertyOrientation: CGImagePropertyOrientation {
    switch self {
    case .portraitUpsideDown:
      return .left
    case .landscapeRight:
      return .upMirrored
    case .landscapeLeft:
      return .down
    case .portrait:
      return .up
    }
  }
}
