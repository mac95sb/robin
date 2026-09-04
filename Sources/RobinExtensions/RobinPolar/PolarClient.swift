import Foundation
import RobinCore

#if canImport(FoundationNetworking)
  import FoundationNetworking
#endif

/// A transport response used by ``PolarClient``.
public struct PolarHTTPResponse: Sendable {
  /// HTTP status code returned by Polar.
  public let statusCode: Int
  /// Complete response body.
  public let body: Data

  /// Creates a transport response.
  public init(statusCode: Int, body: Data) {
    self.statusCode = statusCode
    self.body = body
  }
}

/// The Polar API environment used by a client.
public enum PolarEnvironment: Sendable {
  /// Polar's production API.
  case production
  /// Polar's sandbox API.
  case sandbox
  /// A compatible custom API root, including the `/v1` path.
  case custom(URL)

  var url: URL {
    switch self {
    case .production: URL(string: "https://api.polar.sh/v1")!
    case .sandbox: URL(string: "https://sandbox-api.polar.sh/v1")!
    case .custom(let url): url
    }
  }
}

/// Input for a Polar checkout session.
public struct PolarCheckoutRequest: Encodable, Sendable {
  /// Product identifiers offered by the checkout.
  public let products: [String]
  /// Same-origin or absolute destination after a successful checkout.
  public let successURL: URL
  /// Optional verified customer email.
  public let customerEmail: String?
  /// Stable application account identifier used to reconcile the Polar customer.
  public let externalCustomerID: String?
  /// Non-sensitive values copied to the resulting customer.
  public let customerMetadata: [String: String]

  /// Creates a checkout request.
  public init(
    products: [String],
    successURL: URL,
    customerEmail: String? = nil,
    externalCustomerID: String? = nil,
    customerMetadata: [String: String] = [:]
  ) throws {
    guard !products.isEmpty, products.allSatisfy({ !$0.isEmpty }),
      successURL.scheme == "https" || successURL.scheme == "http"
    else { throw PolarError.invalidInput }
    self.products = products
    self.successURL = successURL
    self.customerEmail = customerEmail
    self.externalCustomerID = externalCustomerID
    self.customerMetadata = customerMetadata
  }
}

/// A created Polar checkout session.
public struct PolarCheckout: Decodable, Equatable, Sendable {
  /// Checkout identifier.
  public let id: String
  /// Current provider status.
  public let status: String
  /// Hosted checkout destination.
  public let url: URL
  /// Associated subscription identifier, when the checkout created one.
  public let subscriptionID: String?
}

/// A Polar subscription projection used by Robin applications.
public struct PolarSubscription: Decodable, Equatable, Sendable {
  /// Subscription identifier.
  public let id: String
  /// Current provider status.
  public let status: String
  /// Subscribed product identifier.
  public let productID: String
  /// Polar customer identifier.
  public let customerID: String
  /// Whether cancellation is scheduled at the current period boundary.
  public let cancelAtPeriodEnd: Bool
  /// Current billing-period end, when supplied by Polar.
  public let currentPeriodEnd: Date?
}

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
    decoder.keyDecodingStrategy = .convertFromSnakeCase
    decoder.dateDecodingStrategy = .iso8601
    do { return try decoder.decode(Output.self, from: response.body) } catch {
      throw PolarError.invalidResponse
    }
  }
}

/// Polar client and webhook failures that are safe to surface without provider response bodies.
public enum PolarError: Error, Equatable, Sendable {
  /// Client configuration is incomplete or unsafe.
  case invalidConfiguration
  /// An operation received invalid input.
  case invalidInput
  /// Polar returned an unsuccessful status.
  case providerStatus(Int)
  /// Polar returned an unusable response.
  case invalidResponse
}

private struct EmptyBody: Encodable {}
