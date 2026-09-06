import RobinContent
import RobinHTML

let content = MarkdownContentParser.parse(
  """
  # Welcome

  Write **Markdown**, publish with Swift.
  """,
  allowedEmbedHosts: []
)
let html = try HTMLRenderer.render(content)
assert(content.diagnostics.isEmpty)
assert(html.contains("<strong>Markdown</strong>"))
print(html)
