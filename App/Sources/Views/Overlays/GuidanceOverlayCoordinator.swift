import Combine

// MARK: - ComponentLogic

protocol ComponentLogic {
  var activity: any Publisher<Bool, Never> { get }
  var isActive: Bool { get }
}

// MARK: - GuidanceOverlayCoordinator

final class GuidanceOverlayCoordinator: ObservableObject {
  enum Component: Equatable {
    case level
    case illumination(lightLevelPercentage: any Publisher<Double?, Never>)
    case objectDetection(detectedObjects: any Publisher<Set<YOLORecognizableObjects>, Never>)

    var componentLogic: ComponentLogic {
      switch self {
      case .level:
        return LevelComponentLogic()
      case let .illumination(lightLevelPercentage):
        return IlluminationComponentLogic(lightLevelPercentage: lightLevelPercentage)
      case let .objectDetection(detectedObjects):
        return ObjectDetectionComponentLogic(detectedObjects: detectedObjects)
      }
    }

    static func == (lhs: Component, rhs: Component) -> Bool {
      switch (lhs, rhs) {
      case (.level, .level),
           (.illumination, .illumination),
           (.objectDetection, .objectDetection):
        return true
      default:
        return false
      }
    }
  }

  @Published var activeComponent: Component? = nil

  private var components: [(component: Component, logic: ComponentLogic)] = []
  private var cancellables = Set<AnyCancellable>()

  func setComponents(_ components: [Component]) {
    self.components = components.map { ($0, $0.componentLogic) }

    cancellables.forEach { $0.cancel() }
    cancellables.removeAll()

    self.components.forEach { _, logic in
      logic.activity
        .sink { [weak self] _ in
          self?.onComponentActivityChanged()
        }
        .store(in: &cancellables)
    }
  }

  deinit {
    cancellables.forEach { $0.cancel() }
  }

  private func onComponentActivityChanged() {
    activeComponent = components.first { _, logic in logic.isActive }?.component
  }
}
