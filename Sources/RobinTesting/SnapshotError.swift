import RobinCore

/// A snapshot could not be recorded or matched.
public enum SnapshotError: Error, Equatable, Sendable {
  /// The snapshot name is not a portable filename stem.
  case invalidName(String)
  /// No recorded snapshot exists for the requested name and format.
  case missing(String)
  /// The generated snapshot differs from its stored value.
  case mismatch(String)
  /// The snapshot destination is outside `.robin`.
  case outputEscapesRobinRoot
}
