import RobinCore
import RobinHTML
import RobinStyle

struct HomePage: Page {
  let path = "/"
  var metadata: Metadata { Metadata(title: "Documentation") }

  var body: ComponentContent {
    Main {
      Heading { "Robin" }
      Text { "Build static sites, server-rendered applications, and APIs in Swift." }
      Text {
        "Start with a blog, dashboard, API service, or realtime chat. Compose typed pages and controllers; Robin infers how to run them."
      }
      Navigation {
        Link("https://github.com/mac95sb/robin#start-a-project") { "Get started" }
        Link("https://github.com/mac95sb/robin/blob/main/TESTING.md") { "Try the framework" }
      }
      .grid(columns: 2, gap: .md)
      Heading(.two) { "Reference and guides" }
      List {
        for module in [
          "RobinCore", "RobinHTML", "RobinStyle", "RobinContent", "RobinForms", "RobinRouting",
          "RobinRuntime", "RobinData", "RobinCache", "RobinJobs", "RobinEmail", "RobinStorage",
          "RobinServer", "RobinAuth", "RobinBuild", "RobinTesting", "RobinTooling", "RobinPlugin",
          "RobinLucide", "RobinPolar", "RobinOAuth", "RobinPostgres",
        ] {
          ListItem {
            Link(
              "https://mac95sb.github.io/robin/reference/\(module)/documentation/\(module.lowercased())"
            ) {
              module
            }
          }
        }
      }
      Heading(.two) { "Native web behavior first" }
      Text {
        "Ordinary pages, links, and forms use HTML and CSS. Select browser modules only for capabilities that require them, including passkeys and WebSockets."
      }
      Text { "This documentation landing page is built with Robin and ships no Robin JavaScript." }
    }
    .frame(maxWidth: 960)
    .padding(.lg)
  }
}
