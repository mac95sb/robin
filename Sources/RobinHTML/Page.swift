import RobinCore

/// A routable component with metadata that overlays application defaults.
public protocol Page: Component {
  /// The absolute path that addresses this page.
  var path: String { get }

  /// Metadata specific to this page.
  var metadata: Metadata { get }
}

extension Page {
  /// The default empty metadata overlay.
  ///
  /// An empty overlay inherits every application-level metadata value when merged.
  public var metadata: Metadata { Metadata() }
}
