import RobinHTML
import RobinRuntime
import Testing

@Test func popoversGenerateNativeRelationships() throws {
  let rendered = try HTMLRenderer.render(
    Popover {
      Button { "Options" }
    } content: {
      Stack {
        Button(command: .dismiss) { "Done" }
      }
    })

  #expect(
    rendered
      == "<button command=\"toggle-popover\" commandfor=\"robin-popover-p0\" type=\"button\">Options</button><div id=\"robin-popover-p0\" popover=\"auto\"><button command=\"hide-popover\" commandfor=\"robin-popover-p0\" type=\"button\">Done</button></div>"
  )
}

@Test func dismissCommandsCanAccompanyStateActions() throws {
  @State var choice = "Card"
  let rendered = try HTMLRenderer.render(
    Popover {
      Button { "Options" }
    } content: {
      Stack {
        Button(command: .dismiss, action: #action { choice = "Counter" }) { "Counter" }
      }
    })

  #expect(rendered.contains("command=\"hide-popover\""))
  #expect(rendered.contains("commandfor=\"robin-popover-p0\""))
  #expect(rendered.contains("data-robin-action="))
}

@Test func popoverIdentifiersFollowRenderOrder() throws {
  let rendered = try HTMLRenderer.render(
    Stack {
      Popover {
        Button { "First" }
      } content: {
        Stack { "One" }
      }
      Popover {
        Button { "Second" }
      } content: {
        Stack { "Two" }
      }
    })

  #expect(rendered.contains("commandfor=\"robin-popover-p0\""))
  #expect(rendered.contains("id=\"robin-popover-p0\""))
  #expect(rendered.contains("commandfor=\"robin-popover-p1\""))
  #expect(rendered.contains("id=\"robin-popover-p1\""))
}
