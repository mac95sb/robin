import RobinHTML
import RobinStyle

/// A navigation or footer link.
struct NavigationLink: Component {
  private let destination: String
  private let identifier: String?
  private let content: ComponentContent

  /// Creates a navigation link to a destination.
  init(_ destination: String, id: String? = nil, @ViewBuilder content: () -> ComponentContent) {
    self.destination = destination
    identifier = id
    self.content = content()
  }

  var body: ComponentContent {
    Link(destination, id: identifier) { content }
      .font(.label, color: .muted, decoration: TextDecoration.none)
      .font(color: .muted, on: .dark)
      .font(color: .accent, on: .hover || .focus)
      .font(color: .accent, on: .dark && (.hover || .focus))
  }
}
