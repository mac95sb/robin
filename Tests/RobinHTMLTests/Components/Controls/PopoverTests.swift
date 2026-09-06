import RobinHTML
import RobinRuntime
import Testing

@Test func popoversUseNativeCommandsAndEscapeTheirTargets() throws {
  let button = try HTMLRenderer.render(Button(command: .toggle("options")) { "Options" })
  #expect(button.contains("command=\"toggle-popover\""))
  #expect(button.contains("commandfor=\"options\""))
  let popover = try HTMLRenderer.render(Popover(id: "options") { "Choices" })
  #expect(popover == "<div id=\"options\" popover=\"auto\">Choices</div>")
  @State var choice = "Card"
  let selection = try HTMLRenderer.render(
    Button(command: .hide("options"), action: #action { choice = "Counter" }) { "Counter" })
  #expect(selection.contains("command=\"hide-popover\""))
  #expect(selection.contains("data-robin-action="))
}
