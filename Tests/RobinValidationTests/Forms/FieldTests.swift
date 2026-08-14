import Testing

@testable import RobinValidation

@Suite("Form field wrapper")
struct FieldTests {
  @Test func fieldWrapperProducesStableProjection() {
    struct FormState {
      @Field("email") var email = "hello@example.com"
    }
    let state = FormState()

    #expect(state.$email.name == "email")
  }
}
