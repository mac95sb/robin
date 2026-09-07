import RobinHTML
import RobinStyle

/// Applies the shared workspace page layout.
struct DashboardPageLayout: Component {
  private let content: ComponentContent

  init(@ViewBuilder content: () -> ComponentContent) { self.content = content() }

  var body: ComponentContent {
    Stack {
      content.grid(columns: 1, gap: .xxl).frame(maxWidth: 1080).flexItem(grow: 1)
    }
    .flex(justify: .center)
    .padding(.lg).padding(.xxl, on: .md)
    .font(.body, color: .foreground, lineHeight: 26)
    .font(.body, color: .foreground, lineHeight: 26, on: .dark)
    .background(color: .background).background(color: .background, on: .dark)
  }
}
