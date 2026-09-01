import Testing

@testable import RobinCore

private enum PortKey: ConfigurationKey { static let defaultValue = 8080 }

@Suite("Typed scoped configuration")
struct ConfigurationValuesTests {
  @Test func scopesDoNotMutateTheirParent() {
    let base = Environment("test")
    let child = base.scoped { $0[PortKey.self] = 9090 }
    #expect(base.values[PortKey.self] == 8080)
    #expect(child.values[PortKey.self] == 9090)
  }

  @Test func secretsStayRedacted() {
    let secret = Secret("token")
    #expect(secret.description == "<redacted>")
    #expect(secret.withValue { $0 } == "token")
  }
}
