import AppDevUtils
import Dependencies
import Vision

// MARK: - CoreMLModelProvider

struct CoreMLModelProvider {
  enum Error: Swift.Error {
    case modelNotFound(modelName: String)
  }

  enum Model {
    case yoloV3_8Bit

    var fileName: String {
      switch self {
      case .yoloV3_8Bit:
        return "YOLOv3Int8LUT"
      }
    }

    var fileExtension: String {
      switch self {
      case .yoloV3_8Bit:
        return "mlmodelc"
      }
    }

    var bundle: Bundle {
      switch self {
      case .yoloV3_8Bit:
        return .main
      }
    }
  }

  var preloadModel: @MainActor (_ model: Model) -> Void
  var getModel: @MainActor (_ model: Model) async throws -> VNCoreMLModel
}

extension DependencyValues {
  var coreMLModelProvider: CoreMLModelProvider {
    get { self[CoreMLModelProvider.self] }
    set { self[CoreMLModelProvider.self] = newValue }
  }
}

// MARK: - CoreMLModelProvider + DependencyKey

extension CoreMLModelProvider: DependencyKey {
  static let liveValue: CoreMLModelProvider = {
    var preloadedModels = [Model: Task<VNCoreMLModel, Swift.Error>]()

    @Sendable
    func loadModel(_ model: Model) -> Task<VNCoreMLModel, Swift.Error> {
      Task<VNCoreMLModel, Swift.Error>.detached(priority: .high) {
        guard let modelURL = model.bundle.url(forResource: model.fileName, withExtension: model.fileExtension) else {
          throw Error.modelNotFound(modelName: "\(model.fileName).\(model.fileExtension)")
        }

        return try VNCoreMLModel(for: MLModel(contentsOf: modelURL))
      }
    }

    return CoreMLModelProvider(
      preloadModel: { model in
        guard preloadedModels[model] == nil else {
          log.warning("Model \(model.fileName) is already being loaded")
          return
        }

        let preloadTask = loadModel(model)

        preloadedModels[model] = preloadTask
      },
      getModel: { model in
        if let preloadedModel = preloadedModels[model] {
          return try await preloadedModel.value
        } else {
          return try await loadModel(model).value
        }
      }
    )
  }()
}
