import RobinHTML
import RobinStyle

/// A prominent or secondary call-to-action link.
struct CallToAction: Component {
  private let destination: String
  private let isPrimary: Bool
  private let content: ComponentContent

  /// Creates a call-to-action link to a destination.
  init(_ destination: String, primary: Bool = true, @ViewBuilder content: () -> ComponentContent) {
    self.destination = destination
    isPrimary = primary
    self.content = content()
  }

  var body: ComponentContent {
    Link(destination) { content }
      .flex(justify: .center, align: .center).frame(width: 160).padding(.md)
      .font(.emphasis, color: isPrimary ? .surface : .foreground, decoration: TextDecoration.none)
      .font(color: isPrimary ? .background : .foreground, on: .dark)
      .background(color: isPrimary ? .accent : .surface)
      .background(color: isPrimary ? .accent : .surface, on: .dark)
      .border(color: .accent, width: 0, radius: .md)
      .background(color: isPrimary ? .accentHover : .cardHover, on: .hover || .focus)
      .background(color: isPrimary ? .accentHover : .cardHover, on: .dark && (.hover || .focus))
  }
}
