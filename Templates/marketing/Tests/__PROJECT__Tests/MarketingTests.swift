import Foundation
import RobinBuild
@_spi(Rendering) import RobinHTML
@_spi(Rendering) import RobinStyle
import RobinTesting
import Testing

@testable import __PROJECT__

@Test func displayedSwiftMatchesTheLiveComponents() throws {
  let template = URL(fileURLWithPath: #filePath)
    .deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
  for (name, displayed) in [
    ("CounterDemo", CounterDemo.source), ("WelcomeCard", WelcomeCard.source),
    ("ToggleDemo", ToggleDemo.source), ("TextDemo", TextDemo.source),
  ] {
    let file = template.appendingPathComponent(
      "Sources/__PROJECT__/Views/Components/Examples/\(name).swift")
    let source = try String(contentsOf: file, encoding: .utf8)
    let implementation = try #require(source.range(of: "  static let source ="))
    #expect(displayed == String(source[..<implementation.lowerBound]) + "}")
  }
}

@Test func marketingPageHasAccessibleLiveExamplesAndDocumentation() throws {
  #expect(AccessibilityAudit.audit(HomePage()).isEmpty)
  let page = HomePage()
  let styles = try StyleCompiler.compile(
    .fragment(page.body.nodes), theme: .starter, mode: .production)
  let html = try HTMLRenderer.render(page, styles: styles.className(for:))
  #expect(html.contains(Site.documentationURL))
  #expect(html.contains("id=\"examples\""))
  #expect(html.contains("data-robin-appearance-choice=\"dark\""))
  let card = WelcomeCard()
  let cardStyles = try StyleCompiler.compile(
    .fragment(card.body.nodes), theme: .starter, mode: .development)
  let cardHTML = try HTMLRenderer.render(card, styles: cardStyles.className(for:))
  #expect(html.contains(cardHTML))
  let script = String(decoding: try SitePreferencesClientModule.asset().bytes, as: UTF8.self)
  #expect(script.contains("localStorage"))
  #expect(html.contains("index.html"))
  #expect(html.contains("styles.css"))
  #expect(html.contains("id=\"demo-count\""))
  #expect(html.contains("Built with Robin."))
}
