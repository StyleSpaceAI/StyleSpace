import Foundation

// MARK: - ErrorUtility

/// https://kandelvijaya.com/2018/04/21/blog_equalityonerror/

class ErrorUtility {
  public static func areEqual(_ lhs: Error, _ rhs: Error) -> Bool {
    lhs.reflectedString == rhs.reflectedString
  }
}

public extension Error {
  var reflectedString: String {
    String(reflecting: self)
  }

  func isEqual(to: Self) -> Bool {
    reflectedString == to.reflectedString
  }
}

public extension NSError {
  func isEqual(to: NSError) -> Bool {
    let lhs = self as Error
    let rhs = to as Error
    return isEqual(to) && lhs.reflectedString == rhs.reflectedString
  }
}

// MARK: - EquatableError

@propertyWrapper
public struct EquatableError: Hashable {
  public typealias Value = Error

  public var wrappedValue: Value

  public init(wrappedValue: Value) {
    self.wrappedValue = wrappedValue
  }

  public var projectedValue: Self {
    get { self }
    set { self = newValue }
  }

  public static func == (lhs: EquatableError, rhs: EquatableError) -> Bool {
    ErrorUtility.areEqual(lhs.wrappedValue, rhs.wrappedValue)
  }

  public func hash(into hasher: inout Hasher) {
    hasher.combine(wrappedValue.reflectedString)
  }
}

// MARK: - EquatableErrorWrapper

public struct EquatableErrorWrapper: Hashable, Error, CustomStringConvertible {
  @EquatableError public var error: Error

  public init(error: Error) {
    self.error = error
  }
}

// MARK: Codable

extension EquatableErrorWrapper: Codable {
  public init(from decoder: Decoder) throws {
    let container = try decoder.singleValueContainer()
    let errorMessage = try container.decode(String.self)
    let nsError = NSError(domain: "EquatableErrorWrapper", code: 0, userInfo: [NSLocalizedDescriptionKey: errorMessage])
    self.init(error: nsError)
  }

  public func encode(to encoder: Encoder) throws {
    var container = encoder.singleValueContainer()
    try container.encode(error.localizedDescription)
  }
}

// MARK: CustomStringConvertible

public extension EquatableErrorWrapper {
  var _domain: String { error._domain }
  var _code: Int { error._code }
  var _userInfo: AnyObject? { error._userInfo }
  func _getEmbeddedNSError() -> AnyObject? { error._getEmbeddedNSError() }

  var description: String {
    "\(error)"
  }

  var localizedDescription: String {
    error.localizedDescription
  }
}

public extension Error {
  var equatable: EquatableErrorWrapper {
    EquatableErrorWrapper(error: self)
  }
}
