import RobinHTML
import RobinStyle
import RobinTheme

/// Presents interactive and server-rendered framework examples.
struct ExamplesSection: Component {
  var body: ComponentContent {
    Section(id: "examples") {
      Stack {
        RobinLabel { Text { "NOTHING UP ITS SLEEVE" }.margin(.zero) }
        RobinTitle { Heading(.two) { "From a few lines to something real." } }
        Text {
          """
          Try the components, then switch files to inspect their Swift, generated
          HTML and CSS, and browser JavaScript. Shared page defaults are kept
          separately.
          """
        }
        .margin(.zero).frame(maxWidth: 720)
      }
      .grid(columns: 1, gap: .md)
      ExampleGallery()
      GreetingSection()
    }
    .grid(columns: 1, gap: .xxl)
  }
}
