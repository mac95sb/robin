/// A typed database query that decodes each returned row.
public struct DatabaseQuery<Result: Sendable>: Sendable {
  /// The database-neutral statement to execute.
  public let statement: SQLStatement
  private let decode: @Sendable (DatabaseRow) throws -> Result

  /// Creates a typed query.
  public init(
    _ statement: SQLStatement,
    decode: @escaping @Sendable (DatabaseRow) throws -> Result
  ) {
    self.statement = statement
    self.decode = decode
  }

  func result(from row: DatabaseRow) throws -> Result { try decode(row) }
}

extension DatabaseConnection {
  /// Executes and decodes a typed query.
  public func fetch<Result: Sendable>(_ query: DatabaseQuery<Result>) async throws -> [Result] {
    try await self.query(query.statement).map(query.result(from:))
  }

  /// Executes a typed query and returns its first row.
  public func first<Result: Sendable>(_ query: DatabaseQuery<Result>) async throws -> Result? {
    try await fetch(query).first
  }
}
