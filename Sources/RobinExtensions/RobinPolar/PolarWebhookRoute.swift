import Crypto
import Foundation
import HTTPTypes
import RobinCore
import RobinJobs
import RobinRouting
import RobinServer

/// A verified Polar webhook route that durably enqueues before acknowledging delivery.
public struct PolarWebhookRoute: APIRoute, ServerRoute {
  private static let idHeader = HTTPField.Name("webhook-id")!
  private static let timestampHeader = HTTPField.Name("webhook-timestamp")!
  private static let signatureHeader = HTTPField.Name("webhook-signature")!

  /// Route metadata used for conflicts and inspection.
  public let metadata = RouteMetadata(
    operationID: "polarWebhook", summary: "Receive a verified Polar webhook")
  /// Route path.
  public let pattern: RoutePattern
  /// Accepted HTTP method.
  public let method = HTTPMethod.post
  /// The route is not nested under Robin's API version prefix.
  public let version: Version? = nil
  /// Durable queue state is required.
  public let requiredCapabilities: TransportCapabilities = .processLocalState

  private let path: String
  private let secret: Secret<String>
  private let jobs: JobClient
  private let tenant: TenantScope<String>
  private let tolerance: TimeInterval
  private let now: @Sendable () -> Date

  /// Creates a Polar webhook route.
  public init(
    path: String = "/_robin/polar/webhook",
    secret: Secret<String>,
    jobs: JobClient,
    tenant: TenantScope<String> = .none,
    tolerance: TimeInterval = 300,
    now: @escaping @Sendable () -> Date = Date.init
  ) throws {
    let segments = path.split(separator: "/").map(String.init)
    guard path.hasPrefix("/"), !path.hasPrefix("//"), !segments.isEmpty,
      !segments.contains("."), !segments.contains(".."), tolerance >= 0,
      !secret.withValue({ $0.isEmpty })
    else { throw PolarError.invalidConfiguration }
    self.path = "/" + segments.joined(separator: "/")
    self.pattern = RoutePattern(segments.map(RoutePattern.Segment.literal))
    self.secret = secret
    self.jobs = jobs
    self.tenant = tenant
    self.tolerance = tolerance
    self.now = now
  }

  /// Verifies and enqueues a matching webhook request.
  public func respond(
    to request: RobinServer.Request,
    context _: RequestContext,
    api: APIConfiguration
  ) async throws -> RobinServer.Response? {
    guard request.path == api.root.value + path,
      request.method.rawValue.caseInsensitiveCompare(method.rawValue) == .orderedSame
    else { return nil }
    guard request.body.count <= 1_048_576,
      let eventID = request.header(Self.idHeader), !eventID.isEmpty,
      let rawTimestamp = request.header(Self.timestampHeader),
      let timestamp = TimeInterval(rawTimestamp),
      abs(now().timeIntervalSince1970 - timestamp) <= tolerance,
      let signature = request.header(Self.signatureHeader),
      validSignature(
        signature, eventID: eventID, timestamp: rawTimestamp, body: Data(request.body))
    else { return .text("Webhook verification failed", status: .unauthorized) }

    let body = Data(request.body)
    guard let envelope = try? JSONDecoder().decode(EventEnvelope.self, from: body),
      !envelope.type.isEmpty
    else { return .text("Invalid webhook payload", status: .badRequest) }
    _ = try await jobs.enqueue(
      PolarWebhookJob(eventID: eventID, eventType: envelope.type, body: body),
      options: JobOptions(idempotencyKey: eventID),
      tenant: tenant)
    return try .json(Acknowledgement(received: true), status: .accepted)
  }

  private func validSignature(
    _ header: String,
    eventID: String,
    timestamp: String,
    body: Data
  ) -> Bool {
    let signatures = header.split(separator: " ").compactMap { value -> Data? in
      let parts = value.split(separator: ",", maxSplits: 1)
      guard parts.count == 2, parts[0] == "v1" else { return nil }
      return Data(base64Encoded: String(parts[1]))
    }
    guard !signatures.isEmpty else { return false }
    var message = Data("\(eventID).\(timestamp).".utf8)
    message.append(body)
    return secret.withValue { secret in
      let keys = [Data(secret.utf8), standardWebhookKey(secret)].compactMap { $0 }
      return keys.contains { key in
        signatures.contains {
          HMAC<SHA256>.isValidAuthenticationCode(
            $0, authenticating: message, using: SymmetricKey(data: key))
        }
      }
    }
  }

  private func standardWebhookKey(_ secret: String) -> Data? {
    let encoded = secret.split(separator: "_", maxSplits: 1).last.map(String.init) ?? secret
    return Data(base64Encoded: encoded)
  }
}

private struct EventEnvelope: Decodable { let type: String }

private struct Acknowledgement: Encodable { let received: Bool }
