@_spi(Rendering) import RobinHTML
import RobinStyle
import RobinTheme
import Testing

@Suite("Robin theme")
struct RobinThemeTests {
  @Test func exposesTheSharedThemeAndComponents() throws {
    #expect(Theme.robin.identity == "robin")

    let component = RobinPage {
      RobinPanel { RobinTitle { Heading { "Welcome" } }.padding(.lg) }
    }
    let styles = try StyleCompiler.compile(
      .fragment(component.body.nodes), theme: .robin, mode: .production)
    #expect(styles.css.contains("max-width:1080px"))
  }

  @Test func exposesTheModernistTheme() {
    #expect(Theme.modernist.identity == "modernist")
    #expect(Theme.modernist.contrastDiagnostics().isEmpty)
  }

  @Test(arguments: [Theme.paper, .terminal, .playground])
  func exposesTheAdditionalThemes(_ theme: Theme) {
    #expect(theme.contrastDiagnostics().isEmpty)
  }
}
