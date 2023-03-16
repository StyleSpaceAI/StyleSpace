import Combine

final class IlluminationComponentLogic: ComponentLogic {
  var activity: any Publisher<Bool, Never> {
    $activitySubject
  }

  var isActive: Bool {
    activitySubject
  }

  @Published private var activitySubject: Bool = false
  private let lightLevelThreshold = 10.0

  init(lightLevelPercentage: some Publisher<Double?, Never>) {
    lightLevelPercentage
      .map { lightLevel in
        lightLevel.map { $0 < self.lightLevelThreshold } ?? false
      }
      .assign(to: &$activitySubject)
  }
}
