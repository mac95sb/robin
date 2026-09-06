import RobinHTML

struct Greeting: Component {
  let message: Message

  var body: ComponentContent { Text { message.text } }
}
