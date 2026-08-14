@resultBuilder
public enum RenderBuilder {
  public static func buildExpression(_ expression: RenderNode) -> [RenderNode] { [expression] }
  public static func buildExpression(_ expression: ElementNode) -> [RenderNode] {
    [.element(expression)]
  }
  public static func buildExpression(_ expression: String) -> [RenderNode] { [.text(expression)] }
  public static func buildBlock(_ components: [RenderNode]...) -> [RenderNode] {
    components.flatMap(\.self)
  }
  public static func buildOptional(_ component: [RenderNode]?) -> [RenderNode] { component ?? [] }
  public static func buildEither(first component: [RenderNode]) -> [RenderNode] { component }
  public static func buildEither(second component: [RenderNode]) -> [RenderNode] { component }
  public static func buildArray(_ components: [[RenderNode]]) -> [RenderNode] {
    components.flatMap(\.self)
  }
}
