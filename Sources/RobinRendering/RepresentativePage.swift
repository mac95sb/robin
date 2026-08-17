/// A fixed-size page used to exercise and measure the render pipeline.
///
/// The page renders twelve sections of four articles each, producing a
/// deterministic tree suitable for benchmark and snapshot validation.
public struct RepresentativePage: ValidationComponent {
  /// Whether the page includes its footer element.
  public let includeFooter: Bool

  /// Creates a representative page.
  ///
  /// - Parameter includeFooter: Whether to render the footer. Defaults to `true`.
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
