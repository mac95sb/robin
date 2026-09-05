import Foundation

#if canImport(FoundationNetworking)
  import FoundationNetworking
#endif

/// A failure while communicating with the AWS Lambda Runtime API.
public enum AWSLambdaRuntimeAPIError: Error, Equatable, Sendable {
  /// The `AWS_LAMBDA_RUNTIME_API` environment value is absent or invalid.
  case missingEndpoint
  /// A Runtime API response omitted the invocation identifier.
  case missingInvocationID
  /// A Runtime API invocation identifier is not one safe URL path component.
  case invalidInvocationID
  /// A Runtime API request returned a non-success HTTP status.
  case unexpectedStatus(Int)
}
