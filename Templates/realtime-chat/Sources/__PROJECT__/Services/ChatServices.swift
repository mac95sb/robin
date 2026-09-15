import Foundation
import RobinAuth
import RobinData

/// Owns persistent authentication and message services.
struct ChatServices: Sendable {
  private let database: SQLiteDatabase
  let messages: MessageStore
  let authentication: AuthStore
  let sessions: AuthSessionManager
  let passkeys: PasskeyService

  init(storage: SQLiteDatabase.Storage = .memory) async throws {
    let database = try await SQLiteDatabase(storage: storage)
    let storage = try await DatabaseKeyValueStore(database: database)
    let authentication = AuthStore(storage)
    let sessions = AuthSessionManager(store: authentication)
    self.database = database
    self.messages = MessageStore(storage)
    self.authentication = authentication
    self.sessions = sessions
    self.passkeys = PasskeyService(
      configuration: try PasskeyConfiguration(
        relyingPartyID: "localhost",
        relyingPartyName: "__PROJECT__",
        origin: Site.origin
      ),
      store: authentication,
      sessions: sessions
    )
  }

  func shutdown() async throws { try await database.shutdown() }
}
