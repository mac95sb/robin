import Foundation
import RobinHTML
import RobinRouting
import RobinServer
import WebAuthn

/// Same-origin browser endpoints for passkey sign-up, sign-in, and sign-out.
///
/// Register this controller alongside session middleware. Its POST endpoints live beneath
/// `/api/v1/auth`; registration creates a new account and authenticates it only after verification.
/// Pair the begin and finish endpoints with ``PasskeyClientModule``. Cookies remain secure and
/// HTTP-only. Serve the application over HTTPS, or localhost during development.
public struct PasskeyController: Controller {
  private let passkeys: PasskeyService
  private let sessions: AuthSessionManager

  /// Creates browser routes using services that share the same authentication store.
  public init(passkeys: PasskeyService, sessions: AuthSessionManager) {
    self.passkeys = passkeys
    self.sessions = sessions
  }

  /// The five authentication endpoints.
  public var body: RouteList {
    for operation in Operation.allCases {
      AuthenticationRoute(operation: operation, passkeys: passkeys, sessions: sessions)
    }
  }

  private enum Operation: String, CaseIterable, Sendable {
    case register = "register/begin"
    case finishRegistration = "register/finish"
    case authenticate = "login/begin"
    case finishAuthentication = "login/finish"
    case logout
  }

  private struct AuthenticationRoute: APIRoute, ServerRoute {
    let operation: Operation
    let passkeys: PasskeyService
    let sessions: AuthSessionManager
    let method = HTTPMethod.post
    let version: Version? = .default
    let requiredCapabilities: TransportCapabilities = [.processLocalState]
    var pattern: RoutePattern {
      RoutePattern(
        (["auth"] + operation.rawValue.split(separator: "/").map(String.init)).map {
          .literal($0)
        })
    }
    var metadata: RouteMetadata {
      .init(operationID: "auth.\(operation.rawValue)", summary: "Passkey \(operation.rawValue).")
    }

    func respond(to request: Request, context: RequestContext, api: APIConfiguration) async throws
      -> Response?
    {
      guard request.method == .post,
        request.path == Version.default.path(relativePath: "auth/\(operation.rawValue)", api: api)
      else { return nil }
      guard request.header(.origin) == passkeys.origin else {
        throw ServerError(.forbidden, "Authentication requires the application's origin.")
      }
      guard request.body.count <= 65_536 else {
        throw ServerError(.init(code: 413), "Credential is too large.")
      }
      do {
        let identity = context.clientAddress ?? "anonymous"
        switch operation {
        case .register:
          let ceremony = try await passkeys.beginRegistration(
            for: Account(name: "Member"), clientIdentity: identity)
          return try .json(Begin(id: ceremony.id, options: ceremony.options))
        case .authenticate:
          let ceremony = try await passkeys.beginAuthentication(clientIdentity: identity)
          return try .json(Begin(id: ceremony.id, options: ceremony.options))
        case .finishRegistration:
          let input: Finish<RegistrationCredential> = try decode(request)
          let credential = try await passkeys.finishRegistration(
            ceremonyID: input.ceremonyID, credential: input.credential)
          return signedIn(try await sessions.create(for: credential.accountID))
        case .finishAuthentication:
          let input: Finish<AuthenticationCredential> = try decode(request)
          return signedIn(
            try await passkeys.finishAuthentication(
              ceremonyID: input.ceremonyID, credential: input.credential))
        case .logout:
          if let token = request.cookie(named: "robin-session") { try await sessions.revoke(token) }
          let returnPath = request.header(.referer).flatMap { URL(string: $0)?.path } ?? "/"
          var response = Response.redirect(to: safeRedirect(returnPath) ? returnPath : "/")
          response.clearSessionCookie()
          return response
        }
      } catch AuthError.rateLimited {
        throw ServerError(.init(code: 429), "Too many authentication attempts.")
      } catch is AuthError {
        throw ServerError(.badRequest, "Authentication could not be completed.")
      }
    }

    private func decode<Value: Decodable>(_ request: Request) throws -> Value {
      guard request.header(.contentType)?.lowercased().hasPrefix("application/json") == true else {
        throw ServerError(.unsupportedMediaType, "Expected a JSON credential.")
      }
      do { return try JSONDecoder().decode(Value.self, from: Data(request.body)) } catch {
        throw ServerError(.badRequest, "Invalid credential response.")
      }
    }

    private func signedIn(_ token: SessionToken) -> Response {
      var response = Response(status: .init(code: 204))
      response.setAuthSessionCookie(token)
      response.head.headerFields[.cacheControl] = "no-store"
      return response
    }
  }

  private struct Begin<Options: Encodable & Sendable>: Encodable, Sendable {
    let id: String
    let options: Options
  }

  private struct Finish<Credential: Decodable>: Decodable {
    let ceremonyID: String
    let credential: Credential
  }
}
