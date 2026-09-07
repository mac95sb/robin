/// The response returned by the readiness endpoint.
struct Health: Encodable, Sendable {
  /// The current readiness value, `"ok"` when the service accepts traffic.
  let status: String
}
