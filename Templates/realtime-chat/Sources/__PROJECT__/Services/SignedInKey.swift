import RobinCore

/// Stores whether the current request has an authenticated account.
struct SignedInKey: ConfigurationKey {
  static let defaultValue = false
}
