import CoreMotion

/// Wrapper around ``CMMotionManager`` to enforce a single instance usage as required by Apple.
/// See https://developer.apple.com/documentation/coremotion/cmmotionmanager
final class MotionManager: CMMotionManager {
  static let instance = MotionManager()

  override private init() {
    super.init()
  }
}
