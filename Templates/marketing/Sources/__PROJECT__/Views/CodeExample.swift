import RobinBuild
@_spi(Rendering) import RobinHTML
@_spi(Rendering) import RobinStyle

struct CodeExample<Preview: Component>: Component {
  let id: String
  let title: String
  let description: String
  let source: String
  let preview: Preview
  let javascript: String?

  var body: ComponentContent {
    let root = RenderNode.fragment(preview.body.nodes)
    let styles = try! StyleCompiler.compile(root, theme: .starter, mode: .development)
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
      Heading(.three) { title }.starterTitle()
      Text { description }.margin(.zero)
      Stack {
        Stack {
          Navigation(id: "\(id)-files") {
            for file in files {
              Link("#\(id)-\(file.language)", id: "\(id)-tab-\(file.language)") {
                file.name
              }.padding(.sm).marketingLink()
                .font(.label, color: .accent, on: .selected)
                .font(.label, color: .accent, on: .dark && .selected)
                .background(color: .cardHover, on: .selected)
                .background(color: .cardHover, on: .dark && .selected)
                .border(color: .border, width: 0, radius: .sm)
            }
          }.flex(wrap: .wrap, align: .center).padding(.sm)
          Stack {}.starterRule()
          for file in files {
            Section(id: "\(id)-\(file.language)") {
              CodeBlock(file.source, language: file.language, theme: .xcode)
                .exampleCode().frame(height: 360)
            }.frame(minWidth: 0)
          }
        }.grid(columns: 1).frame(minWidth: 0).marketingPanel()
        Stack {
          Text { "Live preview" }.margin(.zero).starterLink().padding(.md)
          Stack {}.starterRule()
          Stack { preview }.padding(.lg).frame(minHeight: 360)
            .flex(justify: .center, align: .center)
        }.grid(columns: 1).frame(minWidth: 0).marketingPanel()
      }.grid(columns: 1, gap: .lg).grid(columns: 2, gap: .lg, on: .lg)
    }.grid(columns: 1, gap: .md)
  }
}
