import Testing

@testable import RobinAuth

@Suite("Authorization")
struct AuthorizationTests {
  @Test func authorizationUsesRolePermissions() {
    let principal = AuthPrincipal(
      accountID: "account",
      roles: [Role("editor", permissions: ["articles.edit"])])

    #expect(principal.allows("articles.edit"))
    #expect(!principal.allows("articles.delete"))
  }
}
