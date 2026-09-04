import Foundation
import RobinCore

/// Verifies deterministic text, render-tree, stylesheet, and visual snapshots.
public struct SnapshotTesting {
  /// A snapshot representation and its filename extension.
  public enum Format: String, Sendable {
    /// Rendered HTML.
    case html
    /// Compiled CSS.
    case css
    /// A textual render-tree description.
    case renderTree = "txt"
    /// A browser screenshot.
    case image = "png"
  }

  /// Verifies data against a stored snapshot beneath `.robin/test-results`.
  ///
  /// - Parameters:
  ///   - value: The deterministic snapshot bytes.
  ///   - name: A portable filename stem containing letters, numbers, `-`, or `_`.
  ///   - format: The snapshot representation.
  ///   - layout: The project's generated-output layout.
  ///   - recording: Whether to replace the stored snapshot instead of comparing it.
  /// - Throws: ``SnapshotError`` or a file-system error.
  public static func verify(
    _ value: Data,
    named name: String,
    as format: Format,
    in layout: OutputLayout,
    recording: Bool = false
  ) throws {
    guard !name.isEmpty,
      name.allSatisfy({ $0.isLetter || $0.isNumber || $0 == "-" || $0 == "_" })
    else { throw SnapshotError.invalidName(name) }
    let directory = layout.path(for: .testResults).appendingPathComponent(
      "snapshots", isDirectory: true)
    guard layout.contains(directory) else { throw SnapshotError.outputEscapesRobinRoot }
    let file = directory.appendingPathComponent("\(name).\(format.rawValue)")
    if recording {
      try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
      try value.write(to: file, options: .atomic)
      return
    }
    guard FileManager.default.fileExists(atPath: file.path) else {
      throw SnapshotError.missing(name)
    }
    let expected = try Data(contentsOf: file)
    guard expected == value else { throw SnapshotError.mismatch(name) }
  }

  /// Verifies UTF-8 text against a stored snapshot.
  ///
  /// - Parameters:
  ///   - value: The deterministic snapshot text.
  ///   - name: A portable filename stem.
  ///   - format: The text representation.
  ///   - layout: The project's generated-output layout.
  ///   - recording: Whether to replace the stored snapshot.
  /// - Throws: ``SnapshotError`` or a file-system error.
  public static func verify(
    _ value: String,
    named name: String,
    as format: Format,
    in layout: OutputLayout,
    recording: Bool = false
  ) throws {
    try verify(Data(value.utf8), named: name, as: format, in: layout, recording: recording)
  }
}

/// A snapshot could not be recorded or matched.
public enum SnapshotError: Error, Equatable, Sendable {
  /// The snapshot name is not a portable filename stem.
  case invalidName(String)
  /// No recorded snapshot exists for the requested name and format.
  case missing(String)
  /// The generated snapshot differs from its stored value.
  case mismatch(String)
  /// The snapshot destination is outside `.robin`.
  case outputEscapesRobinRoot
}
