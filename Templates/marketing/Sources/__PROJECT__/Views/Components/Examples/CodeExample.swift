import RobinBuild
@_spi(Rendering) import RobinHTML
@_spi(Rendering) import RobinStyle
import RobinTheme

/// Displays a component alongside its generated source files and live preview.
struct CodeExample<Preview: Component>: Component {
  let title: String
  let description: String
  let source: String
  let preview: Preview
  let javascript: String?

  var body: ComponentContent {
    let root = RenderNode.fragment(preview.body.nodes)
    let styles = try! StyleCompiler.compile(root, theme: .robin, mode: .development)
    let html = try! HTMLRenderer.formatted(root, styles: styles.className(for:))
    let files = [
      (name: "Example.swift", language: "swift", source: source),
      (name: "index.html", language: "html", source: html),
      (name: "styles.css", language: "css", source: styles.rulesCSS),
      (
        name: "client.js", language: "javascript",
        source: javascript ?? "// No JavaScript is needed for this component."
      ),
    ]
    Section {
      RobinTitle { Heading(.three) { title } }
      Text { description }.margin(.zero)
      Stack {
        RobinPanel {
          Stack {
            Tabs {
              for file in files {
                Tab(file.name) {
                  SourceCode(file.source, language: file.language).frame(height: 360)
                }
              }
            }
            .padding(.sm)
          }
          .grid(columns: 1).frame(minWidth: 0)
        }
        RobinPanel {
          Stack {
            RobinLabel { Text { "Live preview" }.margin(.zero).padding(.md) }
            Divider()
            Stack { preview }.padding(.lg).frame(minHeight: 360)
              .flex(justify: .center, align: .center)
          }
          .grid(columns: 1).frame(minWidth: 0)
        }
      }
      .grid(columns: 1, gap: .lg).grid(columns: 2, gap: .lg, on: .lg)
    }
    .grid(columns: 1, gap: .md)
  }
}
