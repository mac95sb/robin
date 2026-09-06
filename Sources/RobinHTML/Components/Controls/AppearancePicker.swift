/// A native dropdown for a persistent system, light, or dark appearance preference.
///
/// Include RobinBuild's `SitePreferencesClientModule` asset to activate the control.
public struct AppearancePicker: Component {
  private let label: String
  private let labels: [String]

  /// Creates an appearance dropdown with localized labels.
  /// - Parameters:
  ///   - accessibilityLabel: The control's accessible name.
  ///   - system: The label for following the device appearance.
  ///   - light: The light appearance label.
  ///   - dark: The dark appearance label.
  public init(
    accessibilityLabel: String = "Appearance", system: String = "System",
    light: String = "Light", dark: String = "Dark"
  ) {
    label = accessibilityLabel
    labels = [system, light, dark]
  }

  /// The native select and its three choices.
  public var body: ComponentContent {
    .node(
      .element(
        RenderElement(
          kind: .select, attributes: [.appearancePicker, .accessibilityLabel(label)],
          children: zip(["system", "light", "dark"], labels).map { value, label in
            .element(
              RenderElement(kind: .option, attributes: [.value(value)], children: [.text(label)]))
          })))
  }
}
