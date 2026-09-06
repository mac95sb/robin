@_spi(Rendering) import RobinRuntime

extension ViewBuilder {
  /// Renders a state binding as escaped text that updates in the browser.
  /// - Parameter expression: The projected state value, such as `$count`.
  /// - Returns: Semantic inline text with its initial value.
  public static func buildExpression<Value: StateValue>(_ expression: StateBinding<Value>)
    -> ComponentContent
  {
    .node(
      .element(
        .init(
          kind: .span, attributes: [.stateText(expression.reference)],
          children: [.text(expression.reference.text)])))
  }
}

extension Component {
  /// Shows the component when Boolean state is true, using the native hidden property.
  /// - Parameter state: The visibility binding.
  /// - Returns: The component with reactive visibility.
  public func visible(_ state: StateBinding<Bool>) -> some Component {
    body.mapTopLevelElements { element in
      RenderElement(
        kind: element.kind,
        attributes: element.attributes + [.stateVisible(state.reference)]
          + (state.initialValue ? [] : [.hidden]),
        styles: element.styles, children: element.children)
    }
  }

  /// Binds visibility to Boolean state. Hidden content remains in the document.
  /// - Parameter state: Content is hidden when this value is true.
  /// - Returns: The component with reactive visibility.
  public func hidden(_ state: StateBinding<Bool>) -> some Component {
    body.mapTopLevelElements { element in
      RenderElement(
        kind: element.kind,
        attributes: element.attributes + [.stateHidden(state.reference)]
          + (state.initialValue ? [.hidden] : []),
        styles: element.styles, children: element.children)
    }
  }

  /// Binds the native disabled property to Boolean state.
  /// Apply to controls that support `disabled`, such as inputs and buttons.
  /// - Parameter state: The control is disabled when this value is true.
  /// - Returns: The component with reactive disabled state.
  public func disabled(_ state: StateBinding<Bool>) -> some Component {
    body.mapTopLevelElements { element in
      RenderElement(
        kind: element.kind,
        attributes: element.attributes + [.stateDisabled(state.reference)]
          + (state.initialValue ? [.disabled] : []),
        styles: element.styles, children: element.children)
    }
  }
}
