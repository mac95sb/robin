import RobinHTML
import RobinStyle

/// A styled appearance preference button.
struct AppearanceOption: Component {
  private let preference: AppearanceButton.Preference
  private let accessibilityLabel: String
  private let content: ComponentContent

  /// Creates an appearance preference option.
  init(
    _ preference: AppearanceButton.Preference,
    accessibilityLabel: String,
    @ViewBuilder content: () -> ComponentContent
  ) {
    self.preference = preference
    self.accessibilityLabel = accessibilityLabel
    self.content = content()
  }

  var body: ComponentContent {
    AppearanceButton(
      preference,
      preferences: Site.preferences.binding,
      accessibilityLabel: accessibilityLabel
    ) { content }
    .flex(align: .center, gap: .sm).padding(.sm)
    .font(.label, color: .foreground, decoration: TextDecoration.none)
    .font(color: .foreground, on: .dark)
    .background(color: .surface).background(color: .surface, on: .dark)
    .border(color: .border, width: 0, radius: .sm)
    .font(color: .accent, on: .pressed)
    .font(color: .accent, on: .dark && .pressed)
    .background(color: .cardHover, on: .hover || .focus)
    .background(color: .cardHover, on: .dark && (.hover || .focus))
  }
}
