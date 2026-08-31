/// A progressive enhancement marker carried in Render IR.
///
/// The marker keeps the structural fallback content alongside an action identifier that a client
/// runtime can interpret when enhancement is available.
public struct RenderEnhancement: Equatable, Sendable {
  /// A stable action identifier interpreted by a later runtime package.
  public let action: String
  /// The enhanced structural content.
  public let content: [RenderNode]

  /// Creates a progressive enhancement marker.
  ///
  /// - Parameters:
  ///   - action: A stable action identifier for the client runtime.
  ///   - content: The structural content available before or without enhancement.
  @_spi(Rendering)
  public init(action: String, content: [RenderNode]) {
    self.action = action
    self.content = content
  }
}
