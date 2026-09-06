import Foundation

/// Enhances a navigation element's same-document links into keyboard-accessible tabs.
/// Without JavaScript, the links navigate to their visible content sections as usual.
/// Register ``asset()`` with the application's build assets. The first panel is selected
/// unless the initial URL fragment identifies another panel. Arrow keys, Home, and End
/// move focus and selection; selecting a tab does not change browser history.
/// Invalid or missing panel targets leave the ordinary links unchanged.
public struct TabsClientModule: Encodable, Sendable {
  /// The navigation element whose links target the panels.
  public let navigationID: String
  /// The accessible name of the tab list.
  public let label: String

  /// Creates a tab binding. Each link must have an identifier and a distinct fragment target.
  /// - Parameters:
  ///   - navigationID: A nonempty navigation identifier without whitespace.
  ///   - label: A nonempty accessible name for the tab list.
  /// - Throws: ``BuildError/invalidRuntimeConfiguration(_:)`` for an invalid identifier or label.
  public init(navigationID: String, label: String) throws {
    guard !navigationID.isEmpty, !navigationID.contains(where: \.isWhitespace), !label.isEmpty
    else { throw BuildError.invalidRuntimeConfiguration("Invalid tab list.") }
    self.navigationID = navigationID
    self.label = label
  }

  /// Creates the framework-owned tab enhancement asset.
  public func asset() throws -> BuildAsset {
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.sortedKeys]
    let config = String(decoding: try encoder.encode(self), as: UTF8.self)
    let source = """
      (() => {
        const config = \(config);
        const list = document.getElementById(config.navigationID);
        if (!list) return;
        const tabs = [...list.querySelectorAll('a[href^="#"]')];
        const panels = tabs.map(tab => document.getElementById(tab.hash.slice(1)));
        if (!tabs.length || tabs.some(tab => !tab.id) || panels.some(panel => !panel)
            || new Set(panels).size !== panels.length) return;
        list.setAttribute("role", "tablist");
        list.setAttribute("aria-label", config.label);
        const select = index => {
          tabs.forEach((tab, i) => {
            tab.setAttribute("aria-selected", String(i === index));
            tab.tabIndex = i === index ? 0 : -1;
            panels[i].hidden = i !== index;
          });
        };
        tabs.forEach((tab, i) => {
          tab.setAttribute("role", "tab");
          tab.setAttribute("aria-controls", panels[i].id);
          panels[i].setAttribute("role", "tabpanel");
          panels[i].setAttribute("aria-labelledby", tab.id);
          panels[i].tabIndex = 0;
          tab.addEventListener("click", event => { event.preventDefault(); select(i); });
          tab.addEventListener("keydown", event => {
            const next = { ArrowRight: (i + 1) % tabs.length,
              ArrowLeft: (i + tabs.length - 1) % tabs.length, Home: 0, End: tabs.length - 1 }[event.key];
            if (next === undefined) return;
            event.preventDefault(); select(next); tabs[next].focus();
          });
        });
        const initial = panels.findIndex(panel => "#" + panel.id === location.hash);
        select(initial < 0 ? 0 : initial);
      })();
      """
    let identity = ContentDigest.sha256(Array(config.utf8)).prefix(16)
    return try BuildAsset(
      reference: "/robin/tabs-\(identity).js", path: "assets/robin-tabs-\(identity).js",
      bytes: Array(source.utf8), mediaType: "text/javascript",
      scriptOrigin: .robinDirectCapability(.navigation, selectedBy: "TabsClientModule"))
  }
}
