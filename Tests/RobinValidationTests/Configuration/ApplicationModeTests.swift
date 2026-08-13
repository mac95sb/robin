import Testing

@testable import RobinValidation

@Suite("Application mode inference")
struct ApplicationModeTests {
  @Test(
    "Infers a mode from registered views and controllers",
    arguments: [
      (hasViews: true, hasControllers: false, expected: ApplicationMode.static),
      (hasViews: false, hasControllers: true, expected: ApplicationMode.api),
      (hasViews: true, hasControllers: true, expected: ApplicationMode.ssr),
    ]
  )
  func infersMode(hasViews: Bool, hasControllers: Bool, expected: ApplicationMode) throws {
    #expect(
      try ApplicationMode(hasViews: hasViews, hasControllers: hasControllers) == expected
    )
  }

  @Test func rejectsApplicationWithoutViewsOrControllers() {
    #expect(throws: ApplicationCompositionError.self) {
      try ApplicationMode(hasViews: false, hasControllers: false)
    }
  }
}
