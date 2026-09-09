import RobinHTML
import RobinStyle
import RobinTheme

/// Provides installation and project-creation instructions.
struct GettingStartedSection: Component {
  let documentationURL: String

  var body: ComponentContent {
    RobinPanel {
      Section(id: "installation") {
        RobinLabel { Text { "GET SET UP" }.margin(.zero) }
        RobinTitle { Heading(.two) { "Installation" } }
        Text {
          """
          With mise installed, install the Robin CLI globally from GitHub:
          """
        }
        .margin(.zero)
        SourceCode("mise use -g github:mac95sb/robin", language: "shell")
      }
      .grid(columns: 1, gap: .md).padding(.lg)
    }

    RobinPanel {
      Section(id: "start-a-project") {
        RobinLabel { Text { "MAKE IT YOURS" }.margin(.zero) }
        RobinTitle { Heading(.two) { "Start a project" } }
        Text {
          """
          With the Robin CLI installed, create your site from the marketing
          template:
          """
        }
        .margin(.zero).frame(maxWidth: 680)
        SourceCode(
          "robin init MySite --template marketing --site-url https://example.com",
          language: "shell"
        )
        Text {
          """
          Make it a product site, a studio, or your own portfolio. Change the
          content and theme tokens; the same Robin components do the rest.
          """
        }
        .margin(.zero).frame(maxWidth: 680)
        MenuLink(documentationURL) { "Explore the Swift DocC documentation →" }
      }
      .grid(columns: 1, gap: .md).padding(.lg)
    }
  }
}
