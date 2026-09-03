import RobinHTML

struct AboutView: Page {
  let path = "/"

  var body: ComponentContent {
    Main {
      Heading { "About __PROJECT__" }
    }
  }
}
