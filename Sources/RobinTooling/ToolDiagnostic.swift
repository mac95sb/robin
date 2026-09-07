import Foundation

package struct ToolDiagnostic: Codable, Equatable, Sendable {
  package struct Measurement: Codable, Equatable, Sendable {
    package let value: Double
    package let unit: String
    package init(value: Double, unit: String) {
      self.value = value
      self.unit = unit
    }
  }

  package enum Severity: String, Codable, Sendable {
    case note
    case warning
    case error
  }

  package struct Location: Codable, Equatable, Sendable {
    package let path: String
    package let line: Int?

    package init(path: String, line: Int? = nil) {
      self.path = path
      self.line = line
    }
  }

  package let code: String
  package let severity: Severity
  package let message: String
  package let location: Location?
  package let remediation: String?
  package let measurement: Measurement?

  package init(
    code: String,
    severity: Severity,
    message: String,
    location: Location? = nil,
    remediation: String? = nil,
    measurement: Measurement? = nil
  ) {
    self.code = code
    self.severity = severity
    self.message = message
    self.location = location
    self.remediation = remediation
    self.measurement = measurement
  }
}
