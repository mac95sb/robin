import Foundation
import RobinCore

/// Result of recording a failed attempt.
public enum JobFailureDisposition: Equatable, Sendable {
  /// The job was rescheduled.
  case retrying(at: Date)
  /// The attempt limit moved the job to dead-letter state.
  case deadLettered
}
