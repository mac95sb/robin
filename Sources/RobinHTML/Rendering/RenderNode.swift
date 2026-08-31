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
    case enhancement(RenderEnhancement)
  }

  @usableFromInline let storage: Storage

  @usableFromInline init(storage: Storage) {
    self.storage = storage
  }
}

@_spi(Rendering)
extension RenderNode {
  /// Creates a node containing a structural element.
  ///
  /// - Parameter element: The element to store.
  /// - Returns: A render node containing the element.
  public static func element(_ element: RenderElement) -> Self { .init(storage: .element(element)) }

  /// Creates a node containing text.
  ///
  /// - Parameter value: The text to store.
  /// - Returns: A render node containing the text.
  public static func text(_ value: String) -> Self { .init(storage: .text(value)) }

  /// Creates a fragment containing child nodes.
  ///
  /// - Parameter children: The child nodes in source order.
  /// - Returns: A fragment render node.
  public static func fragment(_ children: [Self]) -> Self { .init(storage: .fragment(children)) }

  /// Creates a node containing a progressive enhancement marker.
  ///
  /// - Parameter enhancement: The enhancement marker to store.
  /// - Returns: A render node containing the marker.
  public static func enhancement(_ enhancement: RenderEnhancement) -> Self {
    .init(storage: .enhancement(enhancement))
  }

  /// A renderer-facing projection of the node's internal storage.
  public var renderingStorage: RenderingStorage {
    switch storage {
    case .element(let element): .element(element)
    case .text(let text): .text(text)
    case .fragment(let children): .fragment(children)
    case .enhancement(let enhancement): .enhancement(enhancement)
    }
  }

  /// The renderer-facing variants of a structural render node.
  public enum RenderingStorage: Equatable, Sendable {
    /// A typed structural element.
    case element(RenderElement)
    /// A text value.
    case text(String)
    /// An ordered collection of sibling nodes.
    case fragment([RenderNode])
    /// A progressive enhancement marker and its fallback content.
    case enhancement(RenderEnhancement)
  }
}
