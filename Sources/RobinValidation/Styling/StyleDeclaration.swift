import Foundation

/// A normalized property-value pair in a typed style.
public struct StyleDeclaration: Equatable, Hashable, Sendable {
  public let property: StyleProperty
  public let value: String

  public init(_ property: StyleProperty, _ value: String) {
    self.property = property
    self.value = value.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
  }
}
