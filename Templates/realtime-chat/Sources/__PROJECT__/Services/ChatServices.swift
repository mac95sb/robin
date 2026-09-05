import Foundation
import RobinAuth
import RobinData

struct ChatServices: Sendable {
  private let database: SQLiteDatabase
  let storage: any KeyValueStore
  let authentication: AuthStore
  let sessions: AuthSessionManager
  let passkeys: PasskeyService

  init(storage databaseStorage: SQLiteDatabase.Storage = .memory) async throws {
    let database = try await SQLiteDatabase(storage: databaseStorage)
    let storage = try await DatabaseKeyValueStore(database: database)
    let authentication = AuthStore(storage)
    self.database = database
    self.storage = storage
    self.authentication = authentication
    let sessions = AuthSessionManager(store: authentication)
    self.sessions = sessions
    self.passkeys = PasskeyService(
      configuration: try PasskeyConfiguration(
        relyingPartyID: "localhost", relyingPartyName: "__PROJECT__",
        origin: Site.origin),
      store: authentication, sessions: sessions)
  }

  func shutdown() async throws { try await database.shutdown() }
}
