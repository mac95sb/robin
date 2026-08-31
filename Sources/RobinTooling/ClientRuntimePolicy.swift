import RobinCore

/// Validates that a static application's shipped output includes a Robin client-navigation
/// runtime chunk only when explicitly selected.
///
/// A Static Site application ships no Robin client JavaScript unless
/// `.clientNavigation(.enabled)` is explicitly selected; SSR and API applications never emit the
/// static client-navigation runtime, regardless of the setting.
public enum ClientRuntimePolicy {
  /// A policy violation discovered while validating shipped output.
  public enum Violation: Error, Equatable, Sendable {
    /// The build emitted a client-navigation runtime chunk without it being explicitly enabled.
    case unexpectedClientRuntimeChunk(path: String)
  }

  /// The conventional file name Robin emits for the client-navigation runtime chunk.
  public static let runtimeChunkFileName = "robin-client-navigation.js"

  /// Validates a static application's shipped output file paths against the client-navigation
  /// policy.
  ///
  /// - Parameters:
  ///   - mode: The application's inferred rendering mode.
  ///   - clientNavigationEnabled: Whether `.clientNavigation(.enabled)` was explicitly selected.
  ///   - outputFiles: The shipped output's file paths.
  /// - Throws: ``Violation/unexpectedClientRuntimeChunk(path:)`` when `mode` is
  ///   ``ApplicationMode/static``, `clientNavigationEnabled` is `false`, and `outputFiles`
  ///   contains a client-navigation runtime chunk.
  public static func validate(
    mode: ApplicationMode,
    clientNavigationEnabled: Bool,
    outputFiles: [String]
  ) throws {
    guard mode == .static, !clientNavigationEnabled else { return }
    if let match = outputFiles.first(where: { $0.hasSuffix(runtimeChunkFileName) }) {
      throw Violation.unexpectedClientRuntimeChunk(path: match)
    }
  }
}
