import RobinCore
import RobinHTML
import RobinTheme

/// The starter page at the application root.
struct HomePage: Page {
  /// The root URL path.
  let path = "/"

  /// Page-specific metadata that augments the application defaults.
  var metadata: Metadata { Metadata(title: "__PROJECT__") }

  /// Renders the starter greeting.
  var body: ComponentContent {
    RobinPage { Text { "Hello, world!" } }
  }
}
