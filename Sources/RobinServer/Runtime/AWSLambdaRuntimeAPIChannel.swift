import Foundation

#if canImport(FoundationNetworking)
  import FoundationNetworking
#endif

/// Receives and completes invocations through the AWS Lambda Runtime API.
public actor AWSLambdaRuntimeAPIChannel: InvocationChannel {
  private static let version = "2018-06-01"
  private let endpoint: URL
  private let session: URLSession

  /// Creates a channel from the `AWS_LAMBDA_RUNTIME_API` environment value.
  ///
  /// - Throws: ``AWSLambdaRuntimeAPIError/missingEndpoint`` when the environment does not contain
  ///   a valid Runtime API authority.
  public init() throws {
    guard let authority = ProcessInfo.processInfo.environment["AWS_LAMBDA_RUNTIME_API"],
      let endpoint = URL(string: "http://\(authority)")
    else { throw AWSLambdaRuntimeAPIError.missingEndpoint }
    try self.init(endpoint: endpoint)
  }

  /// Creates a channel for a Runtime API endpoint.
  ///
  /// This initializer supports local runtime emulators as well as the endpoint supplied by Lambda.
  ///
  /// - Parameter endpoint: An absolute HTTP or HTTPS Runtime API URL without credentials, a query,
  ///   or a fragment.
  /// - Throws: ``AWSLambdaRuntimeAPIError/missingEndpoint`` when `endpoint` is invalid.
  public init(endpoint: URL) throws {
    guard
      endpoint.host != nil,
      endpoint.scheme == "http" || endpoint.scheme == "https",
      endpoint.user == nil,
      endpoint.password == nil,
      endpoint.query == nil,
      endpoint.fragment == nil
    else { throw AWSLambdaRuntimeAPIError.missingEndpoint }
    self.endpoint = endpoint
    self.session = .shared
  }

  /// Waits for the next Lambda invocation.
  ///
  /// - Returns: The raw event and Runtime API request context.
  /// - Throws: ``AWSLambdaRuntimeAPIError`` or a networking error.
  public func next() async throws -> InvocationEvent? {
    let (data, rawResponse) = try await session.data(from: runtimeURL("invocation/next"))
    let response = try validated(rawResponse)
    guard let id = response.value(forHTTPHeaderField: "Lambda-Runtime-Aws-Request-Id") else {
      throw AWSLambdaRuntimeAPIError.missingInvocationID
    }
    guard Self.isValidInvocationID(id) else {
      throw AWSLambdaRuntimeAPIError.invalidInvocationID
    }
    let deadline = response.value(forHTTPHeaderField: "Lambda-Runtime-Deadline-Ms")
      .flatMap(Int64.init)
      .map { milliseconds in
        let now = Int64(Date().timeIntervalSince1970 * 1_000)
        return ContinuousClock.now.advanced(by: .milliseconds(max(0, milliseconds - now)))
      }
    return InvocationEvent(id: id, payload: Array(data), deadline: deadline)
  }

  /// Posts a successful invocation response.
  ///
  /// - Parameters:
  ///   - invocationID: The Runtime API invocation identifier.
  ///   - payload: The encoded Lambda response envelope.
  /// - Throws: ``AWSLambdaRuntimeAPIError`` or a networking error.
  public func respond(to invocationID: String, with payload: [UInt8]) async throws {
    guard Self.isValidInvocationID(invocationID) else {
      throw AWSLambdaRuntimeAPIError.invalidInvocationID
    }
    try await post(Data(payload), to: "invocation/\(invocationID)/response")
  }

  /// Posts an invocation failure.
  ///
  /// - Parameters:
  ///   - invocationID: The Runtime API invocation identifier.
  ///   - message: The nonempty failure diagnostic reported to Lambda.
  /// - Throws: ``AWSLambdaRuntimeAPIError`` or a networking error.
  public func fail(invocationID: String, with message: String) async throws {
    precondition(message.contains { !$0.isWhitespace })
    struct ErrorEnvelope: Encodable {
      let errorMessage: String
      let errorType = "RobinInvocationFailure"
    }
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.sortedKeys]
    guard Self.isValidInvocationID(invocationID) else {
      throw AWSLambdaRuntimeAPIError.invalidInvocationID
    }
    try await post(
      encoder.encode(ErrorEnvelope(errorMessage: message)),
      to: "invocation/\(invocationID)/error"
    )
  }

  private func post(_ data: Data, to path: String) async throws {
    var request = URLRequest(url: runtimeURL(path))
    request.httpMethod = "POST"
    request.httpBody = data
    request.setValue("application/json", forHTTPHeaderField: "content-type")
    let (_, response) = try await session.data(for: request)
    _ = try validated(response)
  }

  private func runtimeURL(_ path: String) -> URL {
    path.split(separator: "/").reduce(
      endpoint.appendingPathComponent(Self.version).appendingPathComponent("runtime")
    ) { url, component in
      url.appendingPathComponent(String(component))
    }
  }

  private func validated(_ response: URLResponse) throws -> HTTPURLResponse {
    guard let response = response as? HTTPURLResponse, (200..<300).contains(response.statusCode)
    else {
      throw AWSLambdaRuntimeAPIError.unexpectedStatus(
        (response as? HTTPURLResponse)?.statusCode ?? 0)
    }
    return response
  }

  private static func isValidInvocationID(_ value: String) -> Bool {
    !value.isEmpty && !value.contains("/") && value != "." && value != ".."
      && value.allSatisfy { !$0.isWhitespace && !$0.isNewline }
  }
}
