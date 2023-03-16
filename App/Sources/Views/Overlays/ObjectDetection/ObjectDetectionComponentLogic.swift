import Combine
import Foundation

final class ObjectDetectionComponentLogic: ComponentLogic {
  var activity: any Publisher<Bool, Never> {
    $activitySubject
  }

  var isActive: Bool {
    activitySubject
  }

  @Published private var activitySubject: Bool = false

  init(detectedObjects: some Publisher<Set<YOLORecognizableObjects>, Never>) {
    detectedObjects
      .debounce(for: .seconds(0.5), scheduler: RunLoop.main)
      .map { !$0.isEmpty }
      .assign(to: &$activitySubject)
  }
}
