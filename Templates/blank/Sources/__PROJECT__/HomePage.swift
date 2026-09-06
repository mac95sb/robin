import RobinCore
import RobinHTML

struct HomePage: Page {
  let path = "/"
  var metadata: Metadata { Metadata(title: "__PROJECT__") }

  var body: ComponentContent {
    Greeting(message: Message(text: "Hello, world!"))
  }
}
