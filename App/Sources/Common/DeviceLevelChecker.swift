import AppDevUtils
import CoreMotion
import Foundation
import SwiftUI

/// Checks the device tilt relative to the roll axis.
/// NB: Does not (yet) work if the device supports any other orientation than portrait.
final class DeviceLevelChecker: ObservableObject {
  enum State {
    case notStarted
    case level
    case notLevel
  }

  @Published var state: State = .notStarted

  private let motionManager = MotionManager.instance
  private let updateInterval = 0.01

  // Margin in degrees for the device tilt to be considered level.
  // XY margin: how much can horizon be skewed.
  private let tiltMarginXY = 5
  // Z margin: how much can device deviate from being perpendicular to the ground (top/bottom edge skew).
  private let tiltMarginZ = 20

  private var acceleration = CMAcceleration()

  func start() {
    clearAcceleration()

    motionManager.accelerometerUpdateInterval = updateInterval
    motionManager.startAccelerometerUpdates(to: OperationQueue.main) { [weak self] accelerometerData, error in
      guard let accelerometerData, error == nil else {
        log.error("[\(DeviceLevelChecker.self)] Error while getting accelerometer updates, error: \(error?.localizedDescription ?? "nil")")
        return
      }

      self?.updateAccelerometerData(accelerometerData)
    }
  }

  func stop() {
    motionManager.stopAccelerometerUpdates()
    state = .notStarted
  }

  deinit {
    stop()
  }

  // MARK: - Private

  private func updateAccelerometerData(_ data: CMAccelerometerData) {
    // This factor corresponds to a low pass filter with a cutoff of approximately 5Hz for 100Hz input
    let filterFactor = 0.05

    acceleration.x = acceleration.x * (1 - filterFactor) + data.acceleration.x * filterFactor
    acceleration.y = acceleration.y * (1 - filterFactor) + data.acceleration.y * filterFactor
    acceleration.z = acceleration.z * (1 - filterFactor) + data.acceleration.z * filterFactor

    let (radiansX, radiansY, radiansZ) = getVectorAngle()
    updateState(
      orientationDegreesX: Int(radiansX * 180 / Double.pi),
      orientationDegreesY: Int(radiansY * 180 / Double.pi),
      orientationDegreesZ: Int(radiansZ * 180 / Double.pi)
    )
  }

  private func updateState(orientationDegreesX: Int, orientationDegreesY: Int, orientationDegreesZ: Int) {
    if orientationDegreesZ + tiltMarginZ >= 90 &&
      (orientationDegreesX + tiltMarginXY >= 90
        || orientationDegreesX - tiltMarginXY <= 0
        || orientationDegreesY + tiltMarginXY >= 90) {
      state = .level
    } else {
      state = .notLevel
    }
  }

  // Provides the angle of the vector induced by gravity to axes by
  // taking the dot product of the acceleration vector with the axes
  private func getVectorAngle() -> (Double, Double, Double) {
    let magnitude = sqrt(acceleration.x * acceleration.x + acceleration.y * acceleration.y + acceleration.z * acceleration.z)

    let xAxisAngle = acos(fabs(acceleration.x) / magnitude)
    let yAxisAngle = acos(fabs(acceleration.y) / magnitude)
    let zAxisAngle = acos(fabs(acceleration.z) / magnitude)

    return (xAxisAngle, yAxisAngle, zAxisAngle)
  }

  private func clearAcceleration() {
    acceleration.x = 0
    acceleration.y = 0
    acceleration.z = 0
  }
}
