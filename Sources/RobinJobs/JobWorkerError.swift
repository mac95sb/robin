import RobinCore

/// Worker configuration errors.
public enum JobWorkerError: Error, Equatable, Sendable {
  /// No typed handler was registered for a queued job type.
  case missingHandler(String)
}
