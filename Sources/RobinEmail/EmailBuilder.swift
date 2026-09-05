/// Builds a sequence of email-safe components.
@resultBuilder
public struct EmailBuilder {
  private init() {}

  /// Combines component expressions.
  public static func buildBlock(_ components: EmailComponent...) -> EmailComponent {
    .stack(components)
  }

  /// Accepts a component expression.
  public static func buildExpression(_ component: EmailComponent) -> EmailComponent { component }

  /// Converts a string expression into safe text.
  public static func buildExpression(_ text: String) -> EmailComponent { .text(text) }
}
