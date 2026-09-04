import RobinData
import Testing

@Suite("Database-neutral SQL statements")
struct SQLStatementTests {
  @Test func bindingsRenderForEachDialect() throws {
    let table = try SQLIdentifier("users")
    let statement: SQLStatement = "SELECT * FROM \(table) WHERE id = \(7) AND name = \("Robin")"

    let sqlite = statement.render(for: .sqlite)
    #expect(sqlite.sql == "SELECT * FROM \"users\" WHERE id = ? AND name = ?")
    #expect(sqlite.bindings == [.integer(7), .text("Robin")])

    let postgres = statement.render(for: .postgres)
    #expect(postgres.sql == "SELECT * FROM \"users\" WHERE id = $1 AND name = $2")
    #expect(postgres.bindings == sqlite.bindings)
  }

  @Test func unsafeIdentifiersAreRejected() {
    #expect(throws: SQLStatementError.invalidIdentifier("users; DROP TABLE users")) {
      try SQLIdentifier("users; DROP TABLE users")
    }
  }
}
