import RobinHTML
import Testing

@Suite("Main")
struct MainLandmarkTests {
  @Test func mainLowersToMainLandmark() throws {
    let main = try HTMLRenderer.render(Main(id: "content") { Text { "Body" } })

    #expect(main == #"<main id="content"><p>Body</p></main>"#)
  }
}
