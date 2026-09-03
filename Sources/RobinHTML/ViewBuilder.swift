/// Builds component content with native Swift conditionals and loops.
@resultBuilder
public struct ViewBuilder {
  /// Passes resolved content through the builder.
  ///
  /// - Parameter expression: The resolved component content.
  /// - Returns: The supplied content.
  public static func buildExpression(_ expression: ComponentContent) -> ComponentContent {
    expression
  }

  /// Converts a string expression into escaped render-text content.
  ///
  /// - Parameter expression: The text to render.
  /// - Returns: Component content containing a text node.
  public static func buildExpression(_ expression: String) -> ComponentContent {
    .init(nodes: [.text(expression)])
  }

  /// Resolves a component expression into its body content.
  ///
  /// - Parameter expression: The component to resolve.
  /// - Returns: The component's body content.
  public static func buildExpression<C: Component>(_ expression: C) -> ComponentContent {
    expression.body
  }

  /// Combines component content in source order.
  ///
  /// - Parameter components: The content values in the block.
  /// - Returns: Flattened component content.
  public static func buildBlock(_ components: ComponentContent...) -> ComponentContent {
    .init(nodes: components.flatMap(\.nodes))
  }

  /// Builds content for an optional branch.
  ///
  /// - Parameter component: The branch content, or `nil` when the branch is absent.
  /// - Returns: The branch content or empty content.
  public static func buildOptional(_ component: ComponentContent?) -> ComponentContent {
    component ?? .init(nodes: [])
  }

  /// Builds the first branch of a conditional.
  ///
  /// - Parameter component: The selected branch content.
  /// - Returns: The supplied content.
  public static func buildEither(first component: ComponentContent) -> ComponentContent {
    component
  }

  /// Builds the second branch of a conditional.
  ///
  /// - Parameter component: The selected branch content.
  /// - Returns: The supplied content.
  public static func buildEither(second component: ComponentContent) -> ComponentContent {
    component
  }

  /// Combines content produced by a loop.
  ///
  /// - Parameter components: The content values produced by the loop.
  /// - Returns: Flattened component content in iteration order.
  public static func buildArray(_ components: [ComponentContent]) -> ComponentContent {
    .init(nodes: components.flatMap(\.nodes))
  }

  /// Passes availability-gated content through the builder.
  ///
  /// - Parameter component: The content available on the current platform.
  /// - Returns: The supplied content.
  public static func buildLimitedAvailability(_ component: ComponentContent) -> ComponentContent {
    component
  }
}
