import Foundation
import RobinHTML

@main
struct Documentation {
  static func main() throws {
    let navigation = Navigation(id: "robin-site-navigation") {
      Link("/robin/") { "Robin home" }
      " · "
      Link("/robin/reference/RobinCore/documentation/robincore/") { "Documentation" }
    }
    try HTMLRenderer.render(navigation).write(
      to: URL(fileURLWithPath: ".robin/docc-navigation.html"), atomically: true, encoding: .utf8)
  }
}
