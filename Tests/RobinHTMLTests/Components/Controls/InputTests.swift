import RobinHTML
import Testing

@Suite("Input")
struct InputTests {
  @Test func customStepperPreservesNumericInput() throws {
    let html = try HTMLRenderer.render(
      Input(.number, name: "count", showsStepper: false, value: "0", accessibilityLabel: "Count"))
    #expect(html.contains("data-robin-stepper-hidden"))
    #expect(html.contains(#"type="number""#))
    #expect(html.contains(#"value="0""#))
    let text = try HTMLRenderer.render(
      Input(name: "name", showsStepper: false, accessibilityLabel: "Name"))
    #expect(!text.contains("data-robin-stepper-hidden"))
  }

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
