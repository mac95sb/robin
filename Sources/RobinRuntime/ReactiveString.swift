/// A string whose interpolation records references to runtime state.
public struct ReactiveString: ExpressibleByStringInterpolation, Sendable {
  /// A literal string or a reference to a state binding.
  public enum Segment: Equatable, Sendable {
    case literal(String)
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
    public mutating func appendInterpolation<Value>(_ binding: Binding<Value>) {
      segments.append(.state(binding.id))
    }
  }

  public let segments: [Segment]
  public init(stringLiteral value: String) { segments = [.literal(value)] }
  public init(stringInterpolation: StringInterpolation) { segments = stringInterpolation.segments }
}
