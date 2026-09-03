/// A string whose interpolation records references to runtime state.
public struct ReactiveString: ExpressibleByStringInterpolation, Sendable {
  /// A literal string or a reference to a state binding.
  public enum Segment: Equatable, Sendable {
    /// Text copied directly from the string literal.
    case literal(String)
    /// A reference to a binding identifier.
    case state(String)
  }

  /// Storage used while Swift builds an interpolated reactive string.
  public struct StringInterpolation: StringInterpolationProtocol {
    fileprivate var segments: [Segment] = []

    /// Creates empty interpolation storage with the requested capacities.
    ///
    /// - Parameters:
    ///   - literalCapacity: The estimated number of literal characters.
    ///   - interpolationCount: The estimated number of interpolated values.
    public init(literalCapacity: Int, interpolationCount: Int) {
      segments.reserveCapacity(interpolationCount * 2 + 1)
    }

    /// Appends literal text supplied by Swift's string interpolation.
    ///
    /// - Parameter literal: The literal text to append.
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

  /// Creates a reactive string containing one literal segment.
  ///
  /// - Parameter value: The literal text.
  public init(stringLiteral value: String) { segments = [.literal(value)] }

  /// Creates a reactive string from completed interpolation storage.
  ///
  /// - Parameter stringInterpolation: The interpolation storage to consume.
  public init(stringInterpolation: StringInterpolation) { segments = stringInterpolation.segments }
}
