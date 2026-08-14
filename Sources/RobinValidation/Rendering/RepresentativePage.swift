public struct RepresentativePage: ValidationComponent {
  public let includeFooter: Bool

  public init(includeFooter: Bool = true) {
    self.includeFooter = includeFooter
  }

  public var body: [RenderNode] {
    ElementNode(.main, attributes: [RenderAttribute("id", "content")]) {
      ElementNode(.header) { ElementNode(.h1) { "Robin validation" } }
      for section in 1...12 {
        ElementNode(.section, attributes: [RenderAttribute("data-section", "\(section)")]) {
          ElementNode(.h2) { "Section \(section)" }
          for item in 1...4 {
            ElementNode(.article) {
              ElementNode(.p) { "Item \(item) <is escaped>" }
            }
          }
        }
      }
      if includeFooter {
        ElementNode(.footer) { "Measured prototype" }
      }
    }
  }
}
