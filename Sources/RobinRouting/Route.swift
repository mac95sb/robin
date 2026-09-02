import Foundation
import RobinCore

/// A typed route definition used for matching and reverse URL generation.
///
/// A route applies the same literal segments and parameter codec in both directions, keeping
/// accepted paths and generated URLs aligned.
public struct RouteDefinition<Value: Sendable>: Sendable {
  /// Descriptive route metadata available to build and API tooling.
  public let metadata: RouteMetadata
  /// The structural pattern used for matching and route inspection.
  public let pattern: RoutePattern
  private let matchPath: @Sendable ([String]) -> Value?
  private let generatePath: @Sendable (Value) -> [String]

  init(
    metadata: RouteMetadata,
    pattern: RoutePattern,
    match: @escaping @Sendable ([String]) -> Value?,
    generate: @escaping @Sendable (Value) -> [String]
  ) {
    self.metadata = metadata
    self.pattern = pattern
    self.matchPath = match
    self.generatePath = generate
  }

  /// Attempts to match a URL path and decode its typed value.
  ///
  /// Query and fragment components are ignored. Path segments are percent-decoded before they
  /// are compared with literals or passed to the parameter codec. A malformed percent escape
  /// causes matching to fail. Leading and trailing slashes are ignored, while empty interior
  /// segments are preserved.
  ///
  /// - Parameter path: The root-relative or slash-delimited path to match.
  /// - Returns: The decoded route value when every literal and parameter matches; otherwise,
  ///   `nil`.
  public func match(_ path: String) -> Value? {
    guard let components = Self.components(path) else { return nil }
    return matchPath(components)
  }

  /// Generates a root-relative URL for a route value.
  ///
  /// Every literal and encoded parameter segment is percent-encoded independently using the
  /// unreserved URL character set. An empty route generates `/`.
  ///
  /// - Parameter value: The typed value to encode into the route's parameter segment.
  /// - Returns: A root-relative URL with canonically percent-encoded segments.
  public func url(for value: Value) -> String {
    let segments = generatePath(value).map(Self.encode)
    return segments.isEmpty ? "/" : "/" + segments.joined(separator: "/")
  }

  /// Generates an absolute canonical URL for a route value.
  ///
  /// The origin must be an absolute HTTP or HTTPS URL without a path, query, or fragment.
  /// This method does not consult ``RouteMetadata/isCanonical``.
  ///
  /// - Parameters:
  ///   - origin: The absolute origin, such as `https://example.com`.
  ///   - value: The typed value to encode into the route's parameter segment.
  /// - Returns: The absolute route URL, or `nil` when `origin` is not a valid HTTP origin.
  public func canonicalURL(origin: URL, for value: Value) -> URL? {
    guard
      origin.scheme == "http" || origin.scheme == "https",
      origin.host != nil,
      origin.path.isEmpty || origin.path == "/",
      origin.query == nil,
      origin.fragment == nil
    else { return nil }
    return URL(string: url(for: value), relativeTo: origin)?.absoluteURL
  }

  /// Creates a route containing one typed path parameter.
  ///
  /// Matching requires exactly the prefix segments, one decodable parameter segment, and the
  /// suffix segments. Reverse routing inserts the encoded value between the same literals. Empty
  /// literals at the outer route edges are ignored so matching and generation remain symmetric;
  /// empty literals adjacent to the parameter are preserved as interior segments.
  ///
  /// - Parameters:
  ///   - prefix: Literal segments that precede the parameter.
  ///   - parameter: The codec used to decode and encode the parameter segment.
  ///   - suffix: Literal segments that follow the parameter.
  ///   - metadata: Descriptive metadata associated with the route.
  /// - Returns: A route that matches and generates the specified path shape.
  public static func path(
    _ prefix: [String] = [],
    parameter: PathParameter<Value>,
    suffix: [String] = [],
    metadata: RouteMetadata = .init()
  ) -> Self {
    let canonicalPrefix = Array(prefix.drop(while: \.isEmpty))
    let canonicalSuffix = Array(suffix.reversed().drop(while: \.isEmpty).reversed())

    return .init(
      metadata: metadata,
      pattern: RoutePattern(
        canonicalPrefix.map(RoutePattern.Segment.literal)
          + [.parameter(parameter.name)]
          + canonicalSuffix.map(RoutePattern.Segment.literal)
      ),
      match: { components in
        guard components.count == canonicalPrefix.count + 1 + canonicalSuffix.count else {
          return nil
        }
        guard Array(components.prefix(canonicalPrefix.count)) == canonicalPrefix else { return nil }
        guard Array(components.suffix(canonicalSuffix.count)) == canonicalSuffix else { return nil }
        return parameter.decode(components[canonicalPrefix.count])
      },
      generate: { canonicalPrefix + [parameter.encode($0)] + canonicalSuffix }
    )
  }

  private static func components(_ path: String) -> [String]? {
    let pathEnd = path.firstIndex { $0 == "?" || $0 == "#" } ?? path.endIndex
    let encodedComponents = path[..<pathEnd].split(
      separator: "/",
      omittingEmptySubsequences: false
    )

    guard let first = encodedComponents.firstIndex(where: { !$0.isEmpty }) else { return [] }
    guard let last = encodedComponents.lastIndex(where: { !$0.isEmpty }) else { return [] }

    var components: [String] = []
    components.reserveCapacity(encodedComponents.distance(from: first, to: last) + 1)

    for component in encodedComponents[first...last] {
      guard let decoded = String(component).removingPercentEncoding else { return nil }
      components.append(decoded)
    }

    return components
  }

  private static func encode(_ component: String) -> String {
    component.addingPercentEncoding(withAllowedCharacters: .routePathSegment) ?? component
  }
}

extension RouteDefinition where Value == Void {
  /// Creates a route containing only literal path segments.
  ///
  /// Empty leading and trailing literals are ignored so generated URLs match the same paths they
  /// produce. Empty interior literals remain significant.
  ///
  /// - Parameters:
  ///   - segments: The literal segments that must match in order.
  ///   - metadata: Descriptive metadata associated with the route.
  /// - Returns: A value-less route for the specified literal path.
  public static func path(
    _ segments: String...,
    metadata: RouteMetadata = .init()
  ) -> Self {
    let canonicalSegments = Array(
      segments.drop(while: \.isEmpty).reversed().drop(while: \.isEmpty).reversed()
    )

    return .init(
      metadata: metadata,
      pattern: RoutePattern(canonicalSegments.map(RoutePattern.Segment.literal)),
      match: { $0 == canonicalSegments ? () : nil },
      generate: { canonicalSegments }
    )
  }

  /// The root-relative, canonically percent-encoded URL for a literal route.
  public var url: String { url(for: ()) }
}

extension CharacterSet {
  fileprivate static let routePathSegment = CharacterSet.alphanumerics.union(
    CharacterSet(charactersIn: "-._~")
  )
}

extension RouteDefinition: Route {}
