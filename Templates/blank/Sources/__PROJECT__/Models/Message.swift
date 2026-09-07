/// The response returned by the sample message endpoint.
struct Message: Codable, Sendable {
  /// The text rendered on the starter page and returned by the endpoint.
  let text: String
}
