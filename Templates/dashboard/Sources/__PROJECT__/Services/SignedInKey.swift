import RobinCore

/// Stores whether the current request has an authenticated principal.
struct SignedInKey: ConfigurationKey {
  static let defaultValue = false
}
