import RobinCore

struct GreetingKey: ConfigurationKey {
  static let defaultValue = "Hello"
}

let metadata = Metadata(title: "My site", language: "en")
let environment = Environment("development").scoped {
  $0[GreetingKey.self] = "Welcome"
}
let secret = Secret("example-only")

assert(environment.values[GreetingKey.self] == "Welcome")
assert(String(describing: secret) == "<redacted>")
