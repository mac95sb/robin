import RobinHTML

/// Renders a reusable greeting from a message model.
struct Greeting: Component {
  /// The message rendered as the greeting text.
  let message: Message

  /// Renders the message text.
  var body: ComponentContent { Text { message.text } }
}
