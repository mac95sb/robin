import RobinHTML
import Testing

@Suite("Search")
struct SearchTests {
  @Test func searchLowersToSearchLandmark() throws {
    let search = try HTMLRenderer.render(
      Search(id: "site-search") { Input(.search, name: "q", accessibilityLabel: "Search") }
    )

    #expect(
      search
        == #"<search id="site-search"><input aria-label="Search" name="q" type="search"></search>"#
    )
  }
}
