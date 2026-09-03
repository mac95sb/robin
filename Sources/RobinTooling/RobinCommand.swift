import Foundation

package enum ProjectTemplate: String, CaseIterable, Sendable {
  case `static`
  case ssr
  case api
}

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
