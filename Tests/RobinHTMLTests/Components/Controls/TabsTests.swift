import RobinHTML
import Testing

@Suite("Tabs")
struct TabsTests {
  @Test func tabsRenderDeterministicNativeControls() throws {
    let html = try HTMLRenderer.render(
      Tabs {
        Tab("Swift") { Text { "Source" } }
        Tab("HTML") { Text { "Markup" } }
      })

    #expect(
      html
        == """
        <div data-robin-tabs><input checked id="robin-tab-t0-0" name="robin-tabs-t0" type="radio"><label for="robin-tab-t0-0"><span>Swift</span></label><section data-robin-tab-panel><p>Source</p></section><input id="robin-tab-t0-1" name="robin-tabs-t0" type="radio"><label for="robin-tab-t0-1"><span>HTML</span></label><section data-robin-tab-panel><p>Markup</p></section></div>
        """)
  }
}
