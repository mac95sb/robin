import Foundation

package enum RobinCommand: Equatable, Sendable {
  case initialize(name: String, template: ProjectTemplate, templatesDirectory: URL?)
  case dev
  case build
  case export
  case serve
  case worker
  case test
  case lint(json: Bool)
  case doctor(json: Bool)
}
