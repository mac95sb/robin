import RobinCore
import RobinHTML

struct HomePage: Page {
  let path = "/"

  var body: ComponentContent {
    Main {
      Heading { "Robin" }
      Text { "A typed static page." }
    }
  }
}

struct Site: App {
  var metadata: Metadata { Metadata(title: "Robin", language: "en") }

  var pages: some Pages {
    HomePage()
  }
}
