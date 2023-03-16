import CoreMotion

/// Detects device orientation based on the accelerometer data.
enum DeviceOrientationHelper {
  enum Orientation {
    case portrait
    case portraitUpsideDown
    case landscapeLeft // Home button on the left side
    case landscapeRight // Home button on the right side
  }

  static func realOrientation() -> Orientation {
    if !MotionManager.instance.isAccelerometerActive {
      assertionFailure("Accelerometer updates are not running")
    }

    guard let acceleration = MotionManager.instance.accelerometerData?.acceleration else {
      return .portrait
    }

    let splitAngle = 0.75

    if acceleration.x >= splitAngle {
      return .landscapeLeft
    } else if acceleration.x <= -splitAngle {
      return .landscapeRight
    } else if acceleration.y >= splitAngle {
      return .portraitUpsideDown
    } else {
      return .portrait
    }
  }
}
