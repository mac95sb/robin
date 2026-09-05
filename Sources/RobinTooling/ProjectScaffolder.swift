import Foundation

package enum ProjectScaffolderError: Error, Equatable, CustomStringConvertible, Sendable {
  case invalidProjectName(String)
  case templatesUnavailable
  case destinationExists(String)
  case invalidTemplateEntry(String)

  package var description: String {
    switch self {
    case .invalidProjectName(let name):
      "`\(name)` is not a valid Swift project name."
    case .templatesUnavailable:
      "Robin's project templates are unavailable; set ROBIN_TEMPLATES or pass --templates."
    case .destinationExists(let path):
      "The destination `\(path)` already exists."
    case .invalidTemplateEntry(let path):
      "The template entry `\(path)` is unsafe."
    }
  }
}

package struct ProjectScaffolder {
  package static func create(
    name: String,
    template: ProjectTemplate,
    templatesDirectory: URL?,
    projectRoot: URL,
    environment: [String: String] = ProcessInfo.processInfo.environment
  ) throws -> URL {
    guard isValidProjectName(name) else { throw ProjectScaffolderError.invalidProjectName(name) }
    let templates = try resolveTemplatesDirectory(
      explicit: templatesDirectory,
      projectRoot: projectRoot,
      environment: environment
    )
    let source = templates.appendingPathComponent(template.rawValue, isDirectory: true)
    guard
      FileManager.default.fileExists(atPath: source.path),
      try source.resourceValues(forKeys: [.isDirectoryKey]).isDirectory == true
    else { throw ProjectScaffolderError.templatesUnavailable }
    let destination = projectRoot.appendingPathComponent(name, isDirectory: true)
    guard !FileManager.default.fileExists(atPath: destination.path) else {
      throw ProjectScaffolderError.destinationExists(destination.path)
    }
    try FileManager.default.createDirectory(at: destination, withIntermediateDirectories: false)
    do {
      try copyContents(from: source, to: destination, replacing: "__PROJECT__", with: name)
    } catch {
      try? FileManager.default.removeItem(at: destination)
      throw error
    }
    return destination
  }

  private static func resolveTemplatesDirectory(
    explicit: URL?,
    projectRoot: URL,
    environment: [String: String]
  ) throws -> URL {
    let candidates = [
      explicit,
      environment["ROBIN_TEMPLATES"].map { URL(fileURLWithPath: $0) },
      projectRoot.appendingPathComponent("Templates", isDirectory: true),
      sourceCheckoutTemplates,
    ].compactMap { $0 }
    guard
      let directory = candidates.first(where: {
        FileManager.default.fileExists(atPath: $0.path)
      })
    else { throw ProjectScaffolderError.templatesUnavailable }
    return directory.resolvingSymlinksInPath()
  }

  // ponytail: source-based CLI distribution; bundle templates when Robin ships standalone binaries.
  private static var sourceCheckoutTemplates: URL {
    URL(fileURLWithPath: #filePath)
      .deletingLastPathComponent()
      .deletingLastPathComponent()
      .deletingLastPathComponent()
      .appendingPathComponent("Templates", isDirectory: true)
  }

  private static func copyContents(
    from source: URL,
    to destination: URL,
    replacing placeholder: String,
    with projectName: String
  ) throws {
    let manager = FileManager.default
    guard
      let enumerator = manager.enumerator(
        at: source,
        includingPropertiesForKeys: [.isDirectoryKey, .isRegularFileKey, .isSymbolicLinkKey],
        options: []
      )
    else { throw ProjectScaffolderError.templatesUnavailable }
    for case let entry as URL in enumerator {
      let relative = entry.path.replacingOccurrences(of: source.path + "/", with: "")
      let root = String(relative.split(separator: "/").first ?? "")
      if root == ".build" || root == ".swiftpm" {
        if relative == root { enumerator.skipDescendants() }
        continue
      }
      if relative == "Package.resolved" { continue }
      guard !relative.hasPrefix("../"), relative != ".." else {
        throw ProjectScaffolderError.invalidTemplateEntry(relative)
      }
      let output = destination.appendingPathComponent(
        relative.replacingOccurrences(of: placeholder, with: projectName)
      )
      let values = try entry.resourceValues(
        forKeys: [.isDirectoryKey, .isRegularFileKey, .isSymbolicLinkKey])
      guard values.isSymbolicLink != true else {
        throw ProjectScaffolderError.invalidTemplateEntry(relative)
      }
      if values.isDirectory == true {
        try manager.createDirectory(at: output, withIntermediateDirectories: true)
      } else if values.isRegularFile == true {
        let data = try Data(contentsOf: entry)
        if let text = String(data: data, encoding: .utf8) {
          let text =
            text
            .replacingOccurrences(of: placeholder, with: projectName)
            .replacingOccurrences(
              of: #".package(name: "robin", path: "../..")"#,
              with: #".package(url: "https://github.com/mac95sb/robin.git", branch: "main")"#)
          try Data(text.utf8)
            .write(to: output, options: .atomic)
        } else {
          try data.write(to: output, options: .atomic)
        }
      }
    }
  }

  private static func isValidProjectName(_ value: String) -> Bool {
    guard let first = value.first, first.isLetter else { return false }
    return value.allSatisfy { $0.isLetter || $0.isNumber || $0 == "_" }
  }
}
