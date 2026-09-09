import Foundation
@_spi(Rendering) import RobinCore

/// A native radio-backed tab group that requires no JavaScript.
public struct Tabs: Component {
  private let token = UUID().uuidString
  private let tabs: [Tab]

  /// Creates a tab group.
  public init(@TabsBuilder content: () -> [Tab]) {
    tabs = content()
  }

  /// The resolved native radio controls, labels, and panels.
  public var body: ComponentContent {
    .node(
      .element(
        RenderElement(
          kind: .div,
          attributes: [.tabs(token)],
          children: tabs.enumerated().flatMap { index, tab in
            [
              .element(
                RenderElement(
                  kind: .input,
                  attributes: [.inputType(.radio), .tabControl(token, index)]
                    + (index == 0 ? [.checked] : []))),
              .element(
                RenderElement(
                  kind: .label,
                  attributes: [.tabLabel(token, index)],
                  children: Text.phrasingContent(tab.label.body).nodes)),
              .element(
                RenderElement(
                  kind: .section, attributes: [.tabPanel], children: tab.content.nodes)),
            ]
          })))
  }
}

/// One label and panel in ``Tabs``.
public struct Tab: Sendable {
  fileprivate let label: ComponentContent
  fileprivate let content: ComponentContent

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

/// Builds a list of native tabs.
@resultBuilder public enum TabsBuilder {
  public static func buildBlock(_ tabs: [Tab]...) -> [Tab] {
    tabs.flatMap { $0 }
  }
  public static func buildOptional(_ tabs: [Tab]?) -> [Tab] { tabs ?? [] }
  public static func buildEither(first tabs: [Tab]) -> [Tab] { tabs }
  public static func buildEither(second tabs: [Tab]) -> [Tab] { tabs }
  public static func buildArray(_ tabs: [[Tab]]) -> [Tab] {
    tabs.flatMap { $0 }
  }
  public static func buildExpression(_ tab: Tab) -> [Tab] { [tab] }
}
