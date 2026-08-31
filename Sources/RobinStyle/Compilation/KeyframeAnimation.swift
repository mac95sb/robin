import Foundation

/// A deterministic typed keyframe animation.
public struct KeyframeAnimation: Equatable, Sendable {
  public struct Stop: Equatable, Sendable {
    public enum Transform: Equatable, Sendable {
      case scale(Double)
      case translate(x: Int, y: Int)

      var css: String {
        switch self {
        case .scale(let value): "scale(\(Self.decimal(value)))"
        case .translate(let x, let y): "translate(\(x)px,\(y)px)"
        }
      }

      fileprivate static func decimal(_ value: Double) -> String {
        String(format: "%.4f", locale: Locale(identifier: "en_US_POSIX"), value)
          .replacingOccurrences(of: #"0+$"#, with: "", options: .regularExpression)
          .replacingOccurrences(of: #"\.$"#, with: "", options: .regularExpression)
      }
    }

    public let percentage: Int
    public let opacity: Double?
    public let transform: Transform?

    public init(
      _ percentage: Int,
      opacity: Double? = nil,
      transform: Transform? = nil
    ) throws {
      guard (0...100).contains(percentage) else {
        throw AdvancedStyleError.invalidKeyframePercentage(percentage)
      }
      self.percentage = percentage
      self.opacity = opacity.map { min(max($0, 0), 1) }
      self.transform = transform
    }

    var css: String {
      var declarations: [String] = []
      if let opacity {
        declarations.append("opacity:\(Transform.decimal(opacity))")
      }
      if let transform { declarations.append("transform:\(transform.css)") }
      return "\(percentage)%{\(declarations.joined(separator: ";"))}"
    }
  }

  public let stops: [Stop]
  public let name: String

  public init(stops: [Stop]) throws {
    guard !stops.isEmpty else { throw AdvancedStyleError.emptyAnimation }
    self.stops = stops.sorted { $0.percentage < $1.percentage }
    self.name = "r-kf-\(Self.stableHash(self.stops.map(\.css).joined()))"
  }

  var css: String { "@keyframes \(name){\(stops.map(\.css).joined())}" }

  private static func stableHash(_ value: String) -> String {
    var hash: UInt64 = 14_695_981_039_346_656_037
    for byte in value.utf8 {
      hash ^= UInt64(byte)
      hash &*= 1_099_511_628_211
    }
    return String(hash, radix: 36)
  }
}

/// Whether to emit native cross-document View Transition CSS.
public enum ViewTransitionNavigation: Equatable, Sendable {
  case disabled
  case enabled
}
