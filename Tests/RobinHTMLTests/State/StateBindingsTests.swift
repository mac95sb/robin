import Foundation
@_spi(Rendering) import RobinHTML
import RobinRuntime
import Testing

@Suite("Client state rendering")
struct StateBindingsTests {
  @Test func constructingAnActionDoesNotMutateSwiftState() throws {
    @State var count = 0
    let action = #action { count += 10 }
    #expect(count == 0)
    let html = try HTMLRenderer.render(Button(action: action) { "Add ten" })
    #expect(html.contains("data-robin-action"))
    #expect(count == 0)
  }

  private struct Counter: Component {
    @State var count = 0
    var body: ComponentContent {
      Text {
        "Count: "
        $count
      }
      Input(name: "count", value: $count, accessibilityLabel: "Count")
      Button(action: #action { count += 10 }) { "+10" }
      Button(action: $count.reset()) { "Reset" }
    }
  }

  @Test func identifiersAreDeterministicAndInstancesAreIndependent() throws {
    let first = Counter()
    let second = Counter()
    let html = try HTMLRenderer.render(
      Stack {
        first
        second
      })
    #expect(
      html
        == (try HTMLRenderer.render(
          Stack {
            Counter()
            Counter()
          })))
    #expect(html.contains("&quot;s0&quot;"))
    #expect(html.contains("&quot;s1&quot;"))
    #expect(!html.contains("&quot;s2&quot;"))
    #expect(html.contains("add&quot;"))
    #expect(html.contains("Count: <span"))
    #expect(html.contains(">0</span>"))
  }

  @Test func scalarBindingsRenderSafeAndUsefulInitialHTML() throws {
    let name = State(wrappedValue: "<script>bad & \"quoted\"</script>")
    let hidden = State(wrappedValue: true)
    let amount = State(wrappedValue: 0.5)
    let html = try HTMLRenderer.render(
      Stack {
        Text { name.projectedValue }.hidden(hidden.projectedValue)
        Input(name: "name", value: name.projectedValue, accessibilityLabel: "Name")
        Input(name: "enabled", value: hidden.projectedValue, accessibilityLabel: "Enabled")
        Input(name: "amount", value: amount.projectedValue, accessibilityLabel: "Amount")
        Button(action: hidden.projectedValue.toggle()) { "Toggle" }.disabled(hidden.projectedValue)
      })
    #expect(html.contains("&lt;script&gt;bad &amp; &quot;quoted&quot;&lt;/script&gt;"))
    #expect(!html.contains("<script>"))
    #expect(html.contains(" hidden"))
    #expect(html.contains(" disabled"))
    #expect(html.contains(" checked"))
    #expect(html.contains("step=\"any\""))
    #expect(html.contains("type=\"checkbox\""))
  }

  @Test func localBindingsIncludeTheirPersistenceKey() throws {
    @Local("example.appearance") var appearance = "system"
    let html = try HTMLRenderer.render(Button(action: $appearance.set("dark")) { "Dark" })

    #expect(html.contains("example.appearance"))
  }

  @Test func applicationOwnedLocalValuesExposeBindings() throws {
    struct Preferences: Codable, Sendable { var appearance = "system" }
    let preferences = Local("preferences", default: Preferences())
    let html = try HTMLRenderer.render(
      Button(action: preferences.binding.set(.init(appearance: "dark"))) { "Dark" })

    #expect(html.contains("preferences"))
  }
}
