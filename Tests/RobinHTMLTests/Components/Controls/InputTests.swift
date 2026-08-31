import RobinHTML
import Testing

@Suite("Input")
struct InputTests {
  @Test func inputKindsLowerToTypedHTMLTypes() throws {
    let number = try HTMLRenderer.render(
      Input(.number, name: "quantity", accessibilityLabel: "Quantity")
    )
    let telephone = try HTMLRenderer.render(
      Input(.telephone, name: "phone", accessibilityLabel: "Phone")
    )

    #expect(number == #"<input aria-label="Quantity" name="quantity" type="number">"#)
    #expect(telephone == #"<input aria-label="Phone" name="phone" type="tel">"#)
  }
}
