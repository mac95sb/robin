import Foundation
import RobinCore
import RobinHTML
import RobinServer
import RobinStyle
import RobinTheme

/// A minimal Robin application that serves one page and one message endpoint.
@main
struct Site: App {
  var theme: any ApplicationTheme { Theme.robin }

  /// Metadata inherited by every rendered HTML page.
  var metadata: Metadata {
    Metadata(
      site: "__PROJECT__",
      description: "A minimal Robin application.",
      image: .init(
        url: "/social-card.jpg",
        alternativeText: "__PROJECT__ application preview",
        width: 1200,
        height: 630,
        mediaType: "image/jpeg"
      )
    )
  }

  /// Registers the HTML pages served by the application.
  @PagesBuilder var pages: PageList { HomePage() }

  /// Registers the JSON endpoints served by the application.
  @RoutesBuilder var routes: RouteList { MessageController() }

  /// Starts the application with its registered pages and routes.
  static func main() async throws {
    try await RobinApplication.run(Self())
  }
}
