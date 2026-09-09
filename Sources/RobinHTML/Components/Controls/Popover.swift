import Foundation

/// A native popover pairing an invoker with its content without application-defined identifiers.
public struct Popover: Component {
  private let token = UUID().uuidString
  private let trigger: ComponentContent
  private let content: ComponentContent

  /// Creates a popover with a button trigger and one content root.
  ///
  /// Robin generates the target identifier and native anchor relationship.
  /// - Parameters:
  ///   - trigger: A builder producing one button.
  ///   - content: The popover's content.
  public init(
    @ViewBuilder _ trigger: () -> ComponentContent,
    @ViewBuilder content: () -> ComponentContent
  ) {
    self.trigger = trigger()
    self.content = content()
  }

  /// The paired native invoker and popover content.
  public var body: ComponentContent {
    ComponentContent(
      nodes: marked(trigger, as: .popoverTrigger(token), requiring: .button).nodes
        + marked(bindDismissCommands(in: content), as: .popoverContent(token)).nodes
    )
  }

  private func marked(
    _ content: ComponentContent,
    as attribute: RenderElement.Attribute,
    requiring kind: RenderElement.Kind? = nil
  ) -> ComponentContent {
    precondition(content.nodes.count == 1, "Popover builders must produce one root component.")
    var foundRoot = false
    let result = content.mapTopLevelElements { element in
      foundRoot = true
      if let kind { precondition(element.kind == kind, "A popover trigger must be a Button.") }
      return RenderElement(
        kind: element.kind,
        attributes: element.attributes + [attribute],
        styles: element.styles,
        children: element.children
      )
    }
    precondition(foundRoot, "Popover builders must produce one root component.")
    return result
  }

  private func bindDismissCommands(in content: ComponentContent) -> ComponentContent {
    ComponentContent(nodes: content.nodes.map(bindDismissCommands))
  }

  private func bindDismissCommands(in node: RenderNode) -> RenderNode {
    switch node.renderingStorage {
    case .text:
      node
    case .fragment(let children):
      .fragment(children.map(bindDismissCommands))
    case .element(let element):
      .element(
        RenderElement(
          kind: element.kind,
          attributes: element.attributes.map { attribute in
            if case .popoverCommand(.dismiss) = attribute { return .popoverDismiss(token) }
            return attribute
          },
          styles: element.styles,
          children: element.children.map(bindDismissCommands)
        ))
    }
  }
}
