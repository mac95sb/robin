import Foundation
import RobinBuild
import RobinCore
import RobinHTML
import RobinRuntime
import Testing

@Suite("Automatic client state assets")
struct ClientStateTests {
  struct Counter: Component {
    @State var count = 0
    @State var name = "Robin"
    @State var hidden = false
    @State var locked = false
    @State var fraction = 0.5
    @State var hasChanges = false
    @State var edits = 0
    @State var summary = ""
    @State var limit = 9_007_199_254_740_991
    var body: ComponentContent {
      Form {
        Text { "State example" }
        Text { $count }
        Input(name: "count", value: $count, accessibilityLabel: "Count")
        Button(action: #action { count += 1 }) { "+1" }
        Button(action: #action { count += 10 }) { "+10" }
        Button(action: #action { count -= 10 }) { "−10" }
        Button(action: #action { count = 0 }) { "Reset count" }
        Input(name: "name", value: $name, accessibilityLabel: "Name")
          .onInput(action: #action { edits += 1 })
          .onChange(
            action: #action {
              hasChanges = true
              summary = name + "!"
            })
        Text { "Unsaved changes" }.visible($hasChanges)
        Input(name: "edits", value: $edits, accessibilityLabel: "Edits")
        Input(name: "summary", value: $summary, accessibilityLabel: "Summary")
        Text { $name }
        Button(action: #action { name = "<b>Safe & plain</b>" }) { "Set name" }
        Button(action: #action { hidden.toggle() }) { "Toggle visibility" }
        Text { "Details" }.hidden($hidden)
        Input(name: "locked", value: $locked, accessibilityLabel: "Locked")
        Button(action: #action { count += 1 }) { "Guarded increment" }.disabled($locked)
        Input(name: "fraction", value: $fraction, accessibilityLabel: "Fraction")
        Button(action: #action { fraction += 0.5 }) { "+0.5" }
        Input(name: "limit", value: $limit, accessibilityLabel: "Limit")
        Button(action: #action { limit += 1 }) { "Overflow" }
        Button(
          action: #action {
            count = 42
            fraction = 19.95
            name = "Robin updated"
            hidden = !hidden
          }
        ) { "Apply values" }
        Button(
          action: #action {
            count = 123
            limit += 1
            name = "Should not commit"
          }
        ) { "Invalid batch" }
        Button(
          action: #action {
            count = 2
            count = count + 10 - 3
            name += " Swift"
          }
        ) { "Read current values" }
        Button(.reset) { "Reset form" }
      }
    }
  }
  struct CounterPage: Page {
    let path = "/"
    var body: ComponentContent {
      Link("/plain") { "Plain page" }
      Section(id: "first") { Counter() }
      Section(id: "second") { Counter() }
    }
  }
  struct PlainPage: Page {
    let path = "/plain"
    var body: ComponentContent {
      Text { "No state" }
      Link("/") { "Counter page" }
    }
  }
  struct Site: App {
    var clientNavigation: ClientNavigation = .automatic
    var pages: some Pages {
      CounterPage()
      PlainPage()
    }
  }

  @Test func emitsOneAutomaticRuntimeOnlyOnStatefulPages() throws {
    let export = ProcessInfo.processInfo.environment["ROBIN_STATE_BROWSER_OUTPUT"]
    let directory =
      export.map { URL(fileURLWithPath: $0) }
      ?? FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    defer { if export == nil { try? FileManager.default.removeItem(at: directory) } }
    let result = try BuildPipeline.build(Site(), in: .init(projectRoot: directory))
    let scripts = result.manifest.artifacts.filter { $0.mediaType == "text/javascript" }
    #expect(scripts.count == 1)
    let script = try #require(scripts.first)
    #expect(script.scriptOrigin == .robinDirectCapability(.browserAPI, selectedBy: "State"))
    let root = directory.appendingPathComponent(".robin/build")
    let interactive = try String(
      contentsOf: root.appendingPathComponent("index.html"), encoding: .utf8)
    let plain = try String(
      contentsOf: root.appendingPathComponent("plain/index.html"), encoding: .utf8)
    #expect(interactive.contains("/\(script.path)"))
    #expect(!plain.contains("<script"))
    let again = try BuildPipeline.build(Site(), in: .init(projectRoot: directory))
    let rebuilt = try String(contentsOf: root.appendingPathComponent("index.html"), encoding: .utf8)
    #expect(interactive == rebuilt)
    #expect(result.manifest.artifacts.map(\.path) == again.manifest.artifacts.map(\.path))
    if export != nil {
      try BuildPipeline.build(
        Site(clientNavigation: .enabled),
        in: .init(projectRoot: directory.appendingPathComponent("navigation")))
    }
  }
}
