@_spi(Rendering) import RobinRuntime

/// A button that selects a persistent appearance preference.
///
/// HTML reference: [MDN: button](https://developer.mozilla.org/en-US/docs/Web/HTML/Reference/Elements/button).
public struct AppearanceButton: Component {
  /// An appearance preference.
  public enum Preference: String, Codable, Sendable {
    /// Follows the device appearance.
    case system
    /// Uses the light palette.
    case light
    /// Uses the dark palette.
    case dark
  }

  private let preference: Preference
  private let selectedPreference: Preference
  private let label: String
  private let action: StateAction
  private let state: StateReference
  private let content: ComponentContent

  /// Creates an appearance button backed by an application-owned local preferences value.
  /// - Parameters:
  ///   - preference: The appearance to select when activated.
  ///   - preferences: The application-owned local preferences binding.
  ///   - accessibilityLabel: The accessible name, also shown as a native tooltip.
  ///   - content: The button's text or decorative icon.
  public init<Preferences: AppearancePreferences>(
    _ preference: Preference,
    preferences: LocalBinding<Preferences>,
    accessibilityLabel: String,
    @ViewBuilder content: () -> ComponentContent
  ) {
    var updated = preferences.initialValue
    updated.appearance = preference
    self.preference = preference
    selectedPreference = preferences.initialValue.appearance
    label = accessibilityLabel
    action = preferences.set(updated)
    state = preferences.reference
    self.content = content()
  }

  /// The button and its initial selection state.
  public var body: ComponentContent {
    let attributes: [RenderElement.Attribute] = [
      .buttonType(.button), .appearanceChoice(preference),
      .accessibilityLabel(label), .title(label),
      .accessibilityPressed(preference == selectedPreference),
      .stateAction(action), .appearanceState(state),
    ]
    return .node(
      .element(
        RenderElement(
          kind: .button,
          attributes: attributes,
          children: content.nodes)))
  }
}

/// An application-owned preferences value containing an appearance choice.
public protocol AppearancePreferences: Codable, Sendable {
  /// The selected appearance.
  var appearance: AppearanceButton.Preference { get set }
}
