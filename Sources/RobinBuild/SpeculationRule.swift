/// A typed route selected for declarative browser speculation.
public struct SpeculationRule: Codable, Hashable, Sendable {
  /// The browser action requested for a route.
  public enum Action: String, Codable, CaseIterable, Sendable {
    /// Fetch a likely next document without rendering it.
    case prefetch
    /// Fetch and prepare a likely next document for navigation.
    case prerender
  }

  /// How readily the browser may apply a speculation rule.
  public enum Eagerness: String, Codable, CaseIterable, Sendable {
    /// Apply only with strong evidence of imminent navigation.
    case conservative
    /// Balance latency and resource use.
    case moderate
    /// Apply as soon as the rule is observed.
    case eager
  }

  /// The selected action.
  public let action: Action
  /// The registered absolute page path.
  public let path: String
  /// The requested browser eagerness.
  public let eagerness: Eagerness
  /// Asset references required by this candidate.
  public let requiredAssets: [String]

  /// Creates a speculation candidate from typed route and asset metadata.
  ///
  /// - Parameters:
  ///   - action: The requested browser action.
  ///   - path: A registered absolute page path.
  ///   - eagerness: How readily the browser may apply the rule.
  ///   - requiredAssets: Typed asset references required by the candidate.
  public init(
    _ action: Action,
    path: String,
    eagerness: Eagerness = .moderate,
    requiredAssets: [String] = []
  ) {
    self.action = action
    self.path = path
    self.eagerness = eagerness
    self.requiredAssets = Array(Set(requiredAssets)).sorted()
  }
}
