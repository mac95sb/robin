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
