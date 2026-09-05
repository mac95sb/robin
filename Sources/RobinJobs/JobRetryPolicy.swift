import Foundation
import RobinCore

/// Retry limits and exponential-backoff behavior.
public struct JobRetryPolicy: Equatable, Sendable {
  /// Total permitted execution attempts, including the first attempt.
  public let maximumAttempts: Int
  /// Delay before the first retry.
  public let initialDelay: TimeInterval
  /// Maximum exponential delay before jitter is applied.
  public let maximumDelay: TimeInterval
  /// Fractional random variation applied to each delay.
  public let jitter: Double

  /// Creates a bounded exponential retry policy.
  public init(
    maximumAttempts: Int = 3,
    initialDelay: TimeInterval = 1,
    maximumDelay: TimeInterval = 60,
    jitter: Double = 0.2
  ) {
    precondition(maximumAttempts > 0)
    precondition(initialDelay >= 0 && maximumDelay >= initialDelay)
    precondition((0...1).contains(jitter))
    self.maximumAttempts = maximumAttempts
    self.initialDelay = initialDelay
    self.maximumDelay = maximumDelay
    self.jitter = jitter
  }

  /// Calculates the delay for a failed attempt, including jitter.
  ///
  /// - Parameters:
  ///   - attempt: The failed attempt number, starting at one.
  ///   - randomUnit: Random variation in the closed range `-1...1`.
  /// - Returns: A delay that can exceed ``maximumDelay`` by its jitter fraction.
  public func delay(afterAttempt attempt: Int, randomUnit: Double) -> TimeInterval {
    precondition(attempt > 0 && (-1...1).contains(randomUnit))
    let exponential = min(maximumDelay, initialDelay * pow(2, Double(attempt - 1)))
    return exponential * (1 + jitter * randomUnit)
  }
}
