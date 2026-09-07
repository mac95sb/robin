/// A button that selects a persistent appearance preference.
///
/// Include RobinBuild's `SitePreferencesClientModule` asset to activate it.
///
/// HTML reference: [MDN: button](https://developer.mozilla.org/en-US/docs/Web/HTML/Reference/Elements/button).
public struct AppearanceButton: Component {
  /// An appearance preference.
  public enum Preference: String, Sendable {
    /// Follows the device appearance.
    case system
    /// Uses the light palette.
    case light
    /// Uses the dark palette.
    case dark
  }

  private let preference: Preference
  private let label: String
  private let content: ComponentContent

  /// Creates a labeled appearance button with custom visible content.
  /// - Parameters:
  ///   - preference: The appearance to select when activated.
  ///   - accessibilityLabel: The accessible name, also shown as a native tooltip.
  ///   - content: The button's text or decorative icon.
  public init(
    _ preference: Preference, accessibilityLabel: String,
    @ViewBuilder content: () -> ComponentContent
  ) {
    self.preference = preference
    label = accessibilityLabel
    self.content = content()
  }

  /// The button and its initial selection state.
  public var body: ComponentContent {
    .node(
      .element(
        RenderElement(
          kind: .button,
          attributes: [
            .buttonType(.button), .appearanceChoice(preference),
            .accessibilityLabel(label), .title(label), .accessibilityPressed(preference == .system),
          ],
          children: content.nodes)))
  }
}
