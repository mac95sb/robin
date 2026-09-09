import Foundation

extension RobinCommand {
  package var displayName: String {
    switch self {
    case .initialize: "Project creation"
    case .dev: "Development application"
    case .build: "Build"
    case .export: "Export"
    case .serve: "Production application"
    case .worker: "Worker"
    case .test: "Tests"
    case .lint: "Lint"
    case .doctor: "Environment checks"
    }
  }

  package var startMessage: String {
    switch self {
    case .initialize: "Creating the project from its template…"
    case .dev: "Building and starting the development application. Press Ctrl-C to stop."
    case .build: "Building production output…"
    case .export: "Exporting .robin/build to .robin/export…"
    case .serve: "Building and starting the production application. Press Ctrl-C to stop."
    case .worker: "Starting the background worker. Press Ctrl-C to stop."
    case .test: "Running Swift tests…"
    case .lint: "Checking project conventions and Swift formatting…"
    case .doctor: "Checking tools, project configuration, and dependency resolution…"
    }
  }

  package func summary(diagnostics: [ToolDiagnostic]) -> (
    severity: ToolDiagnostic.Severity, message: String, takeaways: [String]
  ) {
    let errors = diagnostics.filter { $0.severity == .error }.count
    let warnings = diagnostics.filter { $0.severity == .warning }.count
    let errorCount = "\(errors) " + (errors == 1 ? "error" : "errors")
    let warningCount = "\(warnings) " + (warnings == 1 ? "warning" : "warnings")
    if errors > 0 {
      return (.error, "\(displayName) failed: \(errorCount), \(warningCount).", [])
    }
    if warnings > 0 {
      return (
        .warning, "\(displayName) completed with \(warningCount) and 0 errors.",
        ["Review the warnings above. Warnings configured as errors cause a failing exit status."]
      )
    }
    switch self {
    case .lint:
      return (
        .note, "Lint passed: 0 errors, 0 warnings.",
        [
          "Checked project conventions and Swift formatting. Performance coverage and skipped checks are listed above. Run `robin test` to check behavior."
        ]
      )
    case .doctor:
      return (.note, "Environment checks passed: 0 errors, 0 warnings.", [])
    case .initialize(let name, let template, _, _):
      let path = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
        .appendingPathComponent(name).path
      return (
        .note, "Created \(name) using the \(template.rawValue) template.",
        ["Project: \(path)", "cd \(name)", "robin dev"]
      )
    case .build:
      return (
        .note, "Production build succeeded.",
        ["Output: .robin/build", "Run `robin export` to prepare a copy for deployment."]
      )
    case .export:
      return (
        .note, "Export completed: .robin/export",
        ["Copied the existing build. Export does not rebuild or deploy the application."]
      )
    case .test:
      return (
        .note, "Swift test run passed.", ["See the test runner output above for test counts."]
      )
    case .dev, .serve, .worker:
      return (.note, "\(displayName) exited successfully.", [])
    }
  }
}
