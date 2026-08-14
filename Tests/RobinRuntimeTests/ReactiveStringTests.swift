import Testing

@testable import RobinRuntime

@Suite("Reactive strings")
struct ReactiveStringTests {
  @Test func interpolationRecordsBindingReference() {
    let binding = Binding<Int>(
      id: "count",
      read: { 0 },
      write: { _ in }
    )
    let text: ReactiveString = "Count: \(binding)"

    #expect(text.segments == [.literal("Count: "), .state("count")])
  }
}
