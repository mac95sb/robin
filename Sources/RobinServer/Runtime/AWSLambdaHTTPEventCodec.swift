import Foundation
import HTTPTypes

/// Converts AWS Lambda HTTP payloads to and from Robin's normalized HTTP values.
public struct AWSLambdaHTTPEventCodec: InvocationEventCodec {
  /// The API Gateway payload format used by the Lambda integration.
  public enum PayloadVersion: String, Sendable {
    /// API Gateway REST API payload format 1.0.
    case v1 = "1.0"
    /// API Gateway HTTP API and Lambda Function URL payload format 2.0.
    case v2 = "2.0"
  }

  /// The response payload format emitted by the codec.
  public let payloadVersion: PayloadVersion

  /// Creates an AWS Lambda HTTP event codec.
  ///
  /// - Parameter payloadVersion: The API Gateway response payload format.
  public init(payloadVersion: PayloadVersion = .v2) {
    self.payloadVersion = payloadVersion
  }

  /// Decodes an API Gateway or Lambda Function URL event.
  ///
  /// - Parameter payload: The complete JSON event bytes.
  /// - Returns: A normalized request and AWS request context.
  /// - Throws: ``InvocationCodecError`` when the event cannot be represented as HTTP.
  public func decode(_ payload: [UInt8]) throws -> DecodedInvocation {
    let event: Event
    do {
      event = try JSONDecoder().decode(Event.self, from: Data(payload))
    } catch {
      throw InvocationCodecError.invalidEvent
    }
    let methodValue = event.requestContext?.http?.method ?? event.httpMethod
    guard let methodValue, let method = HTTPRequest.Method(methodValue) else {
      throw InvocationCodecError.invalidMethod(methodValue ?? "")
    }
    var fields = HTTPFields()
    let repeatedNames = Set(event.multiValueHeaders?.keys.map { $0.lowercased() } ?? [])
    for (name, values) in (event.multiValueHeaders ?? [:]).sorted(by: { $0.key < $1.key }) {
      try append(values, named: name, to: &fields)
    }
    for (name, value) in (event.headers ?? [:]).sorted(by: { $0.key < $1.key })
    where !repeatedNames.contains(name.lowercased()) {
      try append([value], named: name, to: &fields)
    }
    if let cookies = event.cookies, fields[.cookie] == nil {
      try append([cookies.joined(separator: "; ")], named: "cookie", to: &fields)
    }
    let path = event.rawPath ?? event.path ?? event.requestContext?.http?.path ?? "/"
    guard path.hasPrefix("/") else { throw InvocationCodecError.invalidEvent }
    let query = event.rawQueryString ?? encodedQuery(event)
    let target = query.map { $0.isEmpty ? path : "\(path)?\($0)" } ?? path
    let body: [UInt8]
    if let value = event.body {
      if event.isBase64Encoded == true {
        guard let data = Data(base64Encoded: value) else {
          throw InvocationCodecError.invalidBody
        }
        body = Array(data)
      } else {
        body = Array(value.utf8)
      }
    } else {
      body = []
    }
    let request = Request(
      HTTPRequest(
        method: method,
        scheme: fields[HTTPField.Name("x-forwarded-proto")!],
        authority: fields[HTTPField.Name("host")!] ?? event.requestContext?.domainName,
        path: target,
        headerFields: fields
      ),
      body: body
    )
    return DecodedInvocation(
      request: request,
      requestID: event.requestContext?.requestID,
      clientAddress: event.requestContext?.http?.sourceIP
        ?? event.requestContext?.identity?.sourceIP
    )
  }

  /// Encodes an API Gateway or Lambda Function URL response.
  ///
  /// - Parameter response: The buffered application response.
  /// - Returns: Deterministic JSON in the configured payload format.
  /// - Throws: ``InvocationCodecError/unsupportedResponseBody`` for a streaming, file, event, or
  ///   WebSocket body.
  public func encode(_ response: Response) throws -> [UInt8] {
    guard let bytes = response.body.bufferedBytes else {
      throw InvocationCodecError.unsupportedResponseBody
    }
    var headers: [String: String] = [:]
    var multiValueHeaders: [String: [String]] = [:]
    var cookies: [String] = []
    for field in response.head.headerFields {
      if field.name == .setCookie {
        cookies.append(field.value)
      } else {
        multiValueHeaders[field.name.canonicalName, default: []].append(field.value)
        headers[field.name.canonicalName] = field.value
      }
    }
    if payloadVersion == .v2 {
      headers = multiValueHeaders.mapValues { $0.joined(separator: ",") }
    }
    let contentType = response.head.headerFields[.contentType]?.lowercased() ?? ""
    let textual =
      contentType.hasPrefix("text/") || contentType.contains("json")
      || contentType.contains("xml") || contentType.contains("javascript")
    let text = bytes.isEmpty ? "" : textual ? String(bytes: bytes, encoding: .utf8) : nil
    let body = text ?? Data(bytes).base64EncodedString()
    if payloadVersion == .v1, !cookies.isEmpty {
      multiValueHeaders["set-cookie"] = cookies
    }
    let envelope = ResponseEnvelope(
      statusCode: response.head.status.code,
      headers: headers,
      multiValueHeaders: payloadVersion == .v1 ? multiValueHeaders : nil,
      cookies: payloadVersion == .v2 && !cookies.isEmpty ? cookies : nil,
      body: body,
      isBase64Encoded: text == nil
    )
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.sortedKeys]
    return Array(try encoder.encode(envelope))
  }

  private func append(_ values: [String], named rawName: String, to fields: inout HTTPFields)
    throws
  {
    guard let name = HTTPField.Name(rawName) else {
      throw InvocationCodecError.invalidHeader(rawName)
    }
    for value in values { fields.append(HTTPField(name: name, value: value)) }
  }

  private func encodedQuery(_ event: Event) -> String? {
    let values =
      event.multiValueQueryStringParameters
      ?? event.queryStringParameters?.mapValues { [$0] }
    guard let values else { return nil }
    var components = URLComponents()
    components.queryItems = values.keys.sorted().flatMap { key in
      values[key, default: []].map { URLQueryItem(name: key, value: $0) }
    }
    return components.percentEncodedQuery
  }
}

private struct Event: Decodable {
  struct RequestContext: Decodable {
    struct HTTP: Decodable {
      let method: String?
      let path: String?
      let sourceIP: String?

      enum CodingKeys: String, CodingKey {
        case method
        case path
        case sourceIP = "sourceIp"
      }
    }

    struct Identity: Decodable {
      let sourceIP: String?

      enum CodingKeys: String, CodingKey { case sourceIP = "sourceIp" }
    }

    let requestID: String?
    let domainName: String?
    let http: HTTP?
    let identity: Identity?

    enum CodingKeys: String, CodingKey {
      case requestID = "requestId"
      case domainName
      case http
      case identity
    }
  }

  let rawPath: String?
  let rawQueryString: String?
  let path: String?
  let httpMethod: String?
  let headers: [String: String]?
  let multiValueHeaders: [String: [String]]?
  let queryStringParameters: [String: String]?
  let multiValueQueryStringParameters: [String: [String]]?
  let cookies: [String]?
  let body: String?
  let isBase64Encoded: Bool?
  let requestContext: RequestContext?
}

private struct ResponseEnvelope: Encodable {
  let statusCode: Int
  let headers: [String: String]
  let multiValueHeaders: [String: [String]]?
  let cookies: [String]?
  let body: String
  let isBase64Encoded: Bool
}
