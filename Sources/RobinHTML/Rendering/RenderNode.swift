/// A structural node produced by resolving a Robin component tree.
///
/// Render nodes are immutable values shared by static and server rendering. Applications create
/// them through typed components rather than constructing HTML directly.
public struct RenderNode: Equatable, Sendable {
  @usableFromInline
  indirect enum Storage: Equatable, Sendable {
    case element(RenderElement)
    case text(String)
    case fragment([RenderNode])
  }

  @usableFromInline let storage: Storage

  @usableFromInline init(storage: Storage) {
    self.storage = storage
  }

  /// Creates a node containing a structural element.
  ///
  /// - Parameter element: The element to store.
  /// - Returns: A render node containing the element.
  @_spi(Rendering)
  public static func element(_ element: RenderElement) -> Self { .init(storage: .element(element)) }

  /// Creates a node containing text.
  ///
  /// - Parameter value: The text to store.
  /// - Returns: A render node containing the text.
  @_spi(Rendering)
  public static func text(_ value: String) -> Self { .init(storage: .text(value)) }

  /// Creates a fragment containing child nodes.
  ///
  /// - Parameter children: The child nodes in source order.
  /// - Returns: A fragment render node.
  @_spi(Rendering)
  public static func fragment(_ children: [Self]) -> Self { .init(storage: .fragment(children)) }

  /// A renderer-facing projection of the node's internal storage.
  @_spi(Rendering)
  public var renderingStorage: RenderingStorage {
    switch storage {
    case .element(let element): .element(element)
    case .text(let text): .text(text)
    case .fragment(let children): .fragment(children)
    }
  }

  /// The renderer-facing variants of a structural render node.
  @_spi(Rendering)
  public enum RenderingStorage: Equatable, Sendable {
    /// A typed structural element.
    case element(RenderElement)
    /// A text value.
    case text(String)
    /// An ordered collection of sibling nodes.
    case fragment([RenderNode])
  }
}
