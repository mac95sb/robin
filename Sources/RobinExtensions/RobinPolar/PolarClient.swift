import Foundation
import RobinCore

#if canImport(FoundationNetworking)
  import FoundationNetworking
#endif

/// Minimal typed client for Polar checkout and subscription operations.
public struct PolarClient: Sendable {
  /// Request execution supplied by URLSession in production and replaceable in tests.
  public typealias Transport = @Sendable (URLRequest) async throws -> PolarHTTPResponse

  private let accessToken: Secret<String>
  private let baseURL: URL
  private let transport: Transport

  /// Creates a client backed by an ephemeral URL session.
  public init(accessToken: Secret<String>, environment: PolarEnvironment = .production) throws {
    try self.init(accessToken: accessToken, environment: environment) { request in
      let configuration = URLSessionConfiguration.ephemeral
      configuration.timeoutIntervalForRequest = 30
      let (data, response) = try await URLSession(configuration: configuration).data(for: request)
      guard let response = response as? HTTPURLResponse else { throw PolarError.invalidResponse }
      return PolarHTTPResponse(statusCode: response.statusCode, body: data)
    }
  }

  /// Creates a client with an explicit transport.
  public init(
    accessToken: Secret<String>,
    environment: PolarEnvironment = .production,
    transport: @escaping Transport
  ) throws {
    let token = accessToken.withValue { String($0) }
    let baseURL = environment.url
    guard !token.isEmpty, let host = baseURL.host, baseURL.user == nil, baseURL.password == nil,
      baseURL.scheme == "https"
        || (baseURL.scheme == "http" && ["localhost", "127.0.0.1", "::1"].contains(host))
    else { throw PolarError.invalidConfiguration }
    self.accessToken = accessToken
    self.baseURL = baseURL
    self.transport = transport
  }

  /// Creates a hosted checkout session.
  public func createCheckout(_ input: PolarCheckoutRequest) async throws -> PolarCheckout {
    try await send(path: "checkouts/", method: "POST", body: input)
  }

  /// Fetches a subscription by its provider identifier.
  public func subscription(id: String) async throws -> PolarSubscription {
    guard !id.isEmpty else { throw PolarError.invalidInput }
    return try await send(path: "subscriptions/\(id)", method: "GET", body: EmptyBody())
  }

  private func send<Input: Encodable, Output: Decodable>(
    path: String,
    method: String,
    body: Input
  ) async throws -> Output {
    let url = baseURL.appendingPathComponent(path)
    var request = URLRequest(url: url)
    request.httpMethod = method
    request.setValue(
      "Bearer \(accessToken.withValue { String($0) })", forHTTPHeaderField: "Authorization")
    request.setValue("application/json", forHTTPHeaderField: "Accept")
    if method != "GET" {
      request.setValue("application/json", forHTTPHeaderField: "Content-Type")
      let encoder = JSONEncoder()
      encoder.keyEncodingStrategy = .convertToSnakeCase
      request.httpBody = try encoder.encode(body)
    }
    let response = try await transport(request)
    guard (200..<300).contains(response.statusCode) else {
      throw PolarError.providerStatus(response.statusCode)
    }
    let decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .iso8601
    do { return try decoder.decode(Output.self, from: response.body) } catch {
      throw PolarError.invalidResponse
    }
  }
}

private struct EmptyBody: Encodable {}
