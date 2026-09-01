/// A string whose interpolation records references to runtime state.
public struct ReactiveString: ExpressibleByStringInterpolation, Sendable {
  /// A literal string or a reference to a state binding.
  public enum Segment: Equatable, Sendable {
    /// Text copied directly from the string literal.
    case literal(String)
    /// A reference to a binding identifier.
    case state(String)
  }

  public struct StringInterpolation: StringInterpolationProtocol {
    fileprivate var segments: [Segment] = []

    public init(literalCapacity: Int, interpolationCount: Int) {
      segments.reserveCapacity(interpolationCount * 2 + 1)
    }

    public mutating func appendLiteral(_ literal: String) {
      if !literal.isEmpty { segments.append(.literal(literal)) }
    }
    /// Appends a reference to a runtime binding.
    ///
    /// - Parameter binding: The binding referenced by the interpolation.
    public mutating func appendInterpolation<Value>(_ binding: Binding<Value>) {
      segments.append(.state(binding.id))
    }
  }

  /// The recorded literal and state-reference segments.
  public let segments: [Segment]
  public init(stringLiteral value: String) { segments = [.literal(value)] }
  public init(stringInterpolation: StringInterpolation) { segments = stringInterpolation.segments }
}
