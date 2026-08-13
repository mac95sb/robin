import Noora
import PostgresNIO
import SQLiteNIO
import Testing
import WebAuthn

@Test func reviewedExceptionDependenciesLink() {
  _ = Noora()
  _ = WebAuthnManager.Configuration(
    relyingPartyID: "example.com",
    relyingPartyName: "Robin",
    relyingPartyOrigin: "https://example.com"
  )

  // Importing both database clients proves their products are available to a test target.
  _ = SQLiteConnection.self
  _ = PostgresConnection.self
}
