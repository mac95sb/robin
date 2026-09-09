import Foundation
import RobinAuth
import RobinData

/// Owns the storage, authentication, and realtime services for the workspace.
struct DashboardServices: Sendable {
  private let database: SQLiteDatabase
  let storage: any KeyValueStore
  let messages: MessageStore
  let usernames: UsernameStore
  let authentication: AuthStore
  let sessions: AuthSessionManager
  let passkeys: PasskeyService

  init(storage: SQLiteDatabase.Storage = .memory) async throws {
    let database = try await SQLiteDatabase(storage: storage)
    let storage = try await DatabaseKeyValueStore(database: database)
    let authentication = AuthStore(storage)
    self.database = database
    self.storage = storage
    self.messages = MessageStore(storage)
    self.usernames = UsernameStore(storage: storage)
    self.authentication = authentication
    let sessions = AuthSessionManager(store: authentication)
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
