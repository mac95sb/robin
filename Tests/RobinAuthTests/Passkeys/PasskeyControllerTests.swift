import Crypto
import Foundation
import RobinData
import RobinHTML
import RobinServer
import Testing

@testable import RobinAuth

@Test func browserRegistrationAndSignedAuthenticationCreateRevocableSessions() async throws {
  let database = try await TestDatabase.sqlite()
  let store = try await AuthStore(DatabaseKeyValueStore(database: database.database))
  let sessions = AuthSessionManager(store: store)
  let passkeys = PasskeyService(
    configuration: try .init(
      relyingPartyID: "localhost", relyingPartyName: "Example",
      origin: URL(string: "http://localhost:8080")!),
    store: store, sessions: sessions)
  struct Site: App {
    let controller: PasskeyController
    var routes: some Routes { controller }
  }
  let responder = try ApplicationResponder(
    Site(controller: PasskeyController(passkeys: passkeys, sessions: sessions)),
    transportCapabilities: .persistent)
  func post(_ path: String, body: [String: Any] = [:]) async throws -> Response {
    await responder.respond(
      to: Request(
        .init(
          method: .post, scheme: nil, authority: nil, path: "/api/v1/auth/\(path)",
          headerFields: [.origin: "http://localhost:8080", .contentType: "application/json"]),
        body: Array(try JSONSerialization.data(withJSONObject: body))))
  }
  func json(_ response: Response) throws -> [String: Any] {
    guard
      let object = try JSONSerialization.jsonObject(with: Data(response.body.bufferedBytes ?? []))
        as? [String: Any]
    else { throw CocoaError(.coderReadCorrupt) }
    return object
  }
  func base64(_ data: [UInt8]) -> String {
    Data(data).base64EncodedString().replacingOccurrences(of: "+", with: "-")
      .replacingOccurrences(of: "/", with: "_").replacingOccurrences(of: "=", with: "")
  }
  func clientData(_ begin: [String: Any], type: String) throws -> [UInt8] {
    guard let options = begin["options"] as? [String: Any] else {
      throw CocoaError(.coderReadCorrupt)
    }
    return Array(
      try JSONSerialization.data(withJSONObject: [
        "type": type, "challenge": try #require(options["challenge"] as? String),
        "origin": "http://localhost:8080", "crossOrigin": false,
      ]))
  }
  let key = P256.Signing.PrivateKey()
  let point = Array(key.publicKey.x963Representation.dropFirst())
  let credentialID = [UInt8](repeating: 1, count: 16)
  let relyingPartyHash = Array(SHA256.hash(data: Data("localhost".utf8)))
  // Fixed WebAuthn test fixture: a COSE ES256 key and a CBOR "none" attestation.
  let cose: [UInt8] =
    [0xa5, 1, 2, 3, 0x26, 0x20, 1, 0x21, 0x58, 32]
    + Array(point.prefix(32)) + [0x22, 0x58, 32] + Array(point.suffix(32))
  let authData =
    relyingPartyHash + [0x45, 0, 0, 0, 0] + [UInt8](repeating: 0, count: 16)
    + [0, 16] + credentialID + cose
  let attestation: [UInt8] =
    [0xa3, 0x63] + Array("fmt".utf8) + [0x64] + Array("none".utf8)
    + [0x67] + Array("attStmt".utf8) + [0xa0, 0x68] + Array("authData".utf8)
    + [0x58, UInt8(authData.count)] + authData
  let registration = try json(await post("register/begin"))
  let registered = try await post(
    "register/finish",
    body: [
      "ceremonyID": try #require(registration["id"]),
      "credential": [
        "id": base64(credentialID), "rawId": base64(credentialID), "type": "public-key",
        "response": [
          "clientDataJSON": base64(try clientData(registration, type: "webauthn.create")),
          "attestationObject": base64(attestation),
        ],
      ],
    ])
  #expect(registered.head.status.code == 204)
  #expect(registered.head.headerFields[.setCookie]?.contains("HttpOnly") == true)

  let authentication = try json(await post("login/begin"))
  let client = try clientData(authentication, type: "webauthn.get")
  let assertion = relyingPartyHash + [0x05, 0, 0, 0, 1]
  let signature = try key.signature(for: Data(assertion + Array(SHA256.hash(data: client))))
  let finished = try await post(
    "login/finish",
    body: [
      "ceremonyID": try #require(authentication["id"]),
      "credential": [
        "id": base64(credentialID), "rawId": base64(credentialID), "type": "public-key",
        "authenticatorAttachment": "platform",
        "response": [
          "clientDataJSON": base64(client), "authenticatorData": base64(assertion),
          "signature": base64(Array(signature.derRepresentation)),
        ],
      ],
    ])
  #expect(finished.head.status.code == 204)
  let cookie = try #require(finished.head.headerFields[.setCookie])
  let token = try #require(
    cookie.split(separator: ";").first?.split(separator: "=", maxSplits: 1).last
  ).description
  #expect(try await sessions.session(for: token).accountID.isEmpty == false)
  try await sessions.revoke(token)
  await #expect(throws: AuthError.invalidSession) { try await sessions.session(for: token) }
  try await database.remove()
}

@Test func browserPasskeyRoutesRequireOriginAndValidateCredentials() async throws {
  let database = try await TestDatabase.sqlite()
  let store = try await AuthStore(DatabaseKeyValueStore(database: database.database))
  let sessions = AuthSessionManager(store: store)
  let passkeys = PasskeyService(
    configuration: try .init(
      relyingPartyID: "localhost", relyingPartyName: "Example",
      origin: URL(string: "http://localhost:8080")!),
    store: store, sessions: sessions)
  struct Site: App {
    let controller: PasskeyController
    var routes: some Routes { controller }
  }
  let responder = try ApplicationResponder(
    Site(controller: PasskeyController(passkeys: passkeys, sessions: sessions)),
    transportCapabilities: .persistent)
  let begin = Request(
    .init(
      method: .post, scheme: nil, authority: nil, path: "/api/v1/auth/register/begin",
      headerFields: [.origin: "http://localhost:8080"]))
  let response = await responder.respond(to: begin)
  #expect(response.head.status == .ok)
  let json = try #require(
    JSONSerialization.jsonObject(
      with: Data(response.body.bufferedBytes ?? [])) as? [String: Any])
  #expect(json["id"] is String)
  #expect(json["options"] is [String: Any])

  let hostile = await responder.respond(
    to: Request(
      .init(
        method: .post, scheme: nil, authority: nil, path: "/api/v1/auth/register/begin",
        headerFields: [.origin: "https://attacker.example"])))
  #expect(hostile.head.status == .forbidden)
  let invalid = await responder.respond(
    to: Request(
      .init(
        method: .post, scheme: nil, authority: nil, path: "/api/v1/auth/register/finish",
        headerFields: [.origin: "http://localhost:8080", .contentType: "application/json"]),
      body: Array("{}".utf8)))
  #expect(invalid.head.status == .badRequest)
  #expect(invalid.head.headerFields[.setCookie] == nil)

  let account = try Account(name: "Member")
  try await store.save(account)
  let token = try await sessions.create(for: account.id)
  let logout = await responder.respond(
    to: Request(
      .init(
        method: .post, scheme: nil, authority: nil, path: "/api/v1/auth/logout",
        headerFields: [.origin: "http://localhost:8080", .cookie: "robin-session=\(token.value)"])))
  #expect(logout.head.status == .seeOther)
  await #expect(throws: AuthError.invalidSession) { try await sessions.session(for: token.value) }
  try await database.remove()
}
