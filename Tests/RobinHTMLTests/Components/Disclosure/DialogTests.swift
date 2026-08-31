import RobinHTML
import Testing

@Suite("Dialog")
struct DialogTests {
  @Test func closedDialogOmitsOpenAttribute() throws {
    let dialog = try HTMLRenderer.render(Dialog { Text { "Confirm?" } })

    #expect(dialog == "<dialog><p>Confirm?</p></dialog>")
  }

  @Test func openDialogEmitsBareOpenAttribute() throws {
    let dialog = try HTMLRenderer.render(
      Dialog(open: true, accessibilityLabel: "Confirmation") { Text { "Confirm?" } }
    )

    #expect(dialog == #"<dialog aria-label="Confirmation" open><p>Confirm?</p></dialog>"#)
  }
}
