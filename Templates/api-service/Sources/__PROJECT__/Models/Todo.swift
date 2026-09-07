import Foundation
import RobinRouting

/// A todo returned by the catalog endpoints.
///
/// Create requests include only `title`. Robin assigns an identifier and marks new todos as
/// incomplete.
@Resource
struct Todo: Codable, Sendable {
  /// The server-generated identifier.
  private(set) var id: UUID = UUID()
  /// The text summarising the todo item.
  let title: String
  /// Whether the todo is complete.
  private(set) var completed: Bool = false
}
