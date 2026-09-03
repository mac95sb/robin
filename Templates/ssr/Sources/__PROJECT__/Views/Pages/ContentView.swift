import RobinHTML

struct ContentView: Page {
  let path = "/"

  var body: ComponentContent {
    Main {
      Heading { "__PROJECT__" }
      Text { "Server-rendered with Robin." }
    }
  }
}
