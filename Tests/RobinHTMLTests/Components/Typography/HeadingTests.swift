import RobinHTML
import Testing

@Suite("Heading")
struct HeadingTests {
  @Test(
    arguments: [
      (Heading.Level.one, "h1"),
      (.two, "h2"),
      (.three, "h3"),
      (.four, "h4"),
      (.five, "h5"),
      (.six, "h6"),
    ])
  func headingLevelsLowerToSemanticHTML(
    level: Heading.Level,
    element: String
  ) throws {
    let heading = try HTMLRenderer.render(
      Heading(level, id: "name") {
        "Name"
      }
    )

    #expect(heading == #"<\#(element) id="name">Name</\#(element)>"#)
  }

  @Test func directStringRemainsBareHeadingText() throws {
    let heading = try HTMLRenderer.render(Heading { "Hello, world!" })

    #expect(heading == "<h1>Hello, world!</h1>")
  }

  @Test func nestedTextCreatesAnInlineSegment() throws {
    let heading = try HTMLRenderer.render(Heading { Text { "Heading" } })

    #expect(heading == "<h1><span>Heading</span></h1>")
  }

  @Test func multipleTextValuesCreateIntentionalInlineSegments() throws {
    let heading = try HTMLRenderer.render(
      Heading {
        Text { "Cool" }
        Text { "Name" }
      }
    )

    #expect(heading == "<h1><span>Cool</span><span>Name</span></h1>")
  }
}
