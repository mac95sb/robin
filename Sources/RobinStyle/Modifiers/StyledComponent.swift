@_spi(Rendering) import RobinCore
@_spi(Rendering) import RobinHTML

struct StyledComponent<Content: RobinHTML.Component>: RobinHTML.Component {
  private let content: Content
  private let declarations: [StyleDeclaration]

  init(content: Content, declarations: [StyleDeclaration]) {
    self.content = content
    self.declarations = declarations
  }

  var body: RobinHTML.ComponentContent {
    content.body.mapTopLevelElements { element in
      RobinHTML.RenderElement(
        kind: element.kind,
        attributes: element.attributes,
        styles: element.styles + declarations,
        children: element.children
      )
    }
  }
}
