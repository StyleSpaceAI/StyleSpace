import Combine
import Foundation

final class LevelComponentLogic: ComponentLogic {
  var activity: any Publisher<Bool, Never> {
    $activitySubject
  }

  var isActive: Bool {
    activitySubject
  }

  @Published private var activitySubject: Bool = false

  private let levelChecker: DeviceLevelChecker = .init()

  init() {
    levelChecker.start()

    levelChecker.$state
      .throttle(for: .seconds(0.1), scheduler: RunLoop.main, latest: true)
      .map { $0 == .notLevel }
      .assign(to: &$activitySubject)
  }

  deinit {
    levelChecker.stop()
  }
}
