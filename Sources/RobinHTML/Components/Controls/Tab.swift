/// One label and panel in ``Tabs``.
public struct Tab: Sendable {
  let label: ComponentContent
  let content: ComponentContent

  /// Creates a tab with a visible label and panel content.
  public init(
    @ViewBuilder label: () -> ComponentContent,
    @ViewBuilder content: () -> ComponentContent
  ) {
    self.label = label()
    self.content = content()
  }

  /// Creates a tab with a text label and panel content.
  public init(_ label: String, @ViewBuilder content: () -> ComponentContent) {
    self.init(label: { Text { label } }, content: content)
  }
}
