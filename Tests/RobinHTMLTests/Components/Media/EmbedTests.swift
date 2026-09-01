import Foundation
import RobinHTML
import Testing

@Suite("Embed")
struct EmbedTests {
  @Test func allowedHTTPSOriginRendersSandboxedIframe() throws {
    let embed = try Embed(
      source: #require(URL(string: "https://video.example/watch/1")),
      title: "Demo",
      allowedOrigins: ["https://video.example"]
    )
    #expect(
      try HTMLRenderer.render(embed)
        == "<iframe sandbox=\"\" src=\"https://video.example/watch/1\" title=\"Demo\"></iframe>"
    )
  }

  @Test func unlistedOriginsAreRejected() throws {
    let url = try #require(URL(string: "https://other.example/embed"))
    #expect(throws: Embed.ValidationError.self) {
      try Embed(source: url, title: "No", allowedOrigins: ["https://video.example"])
    }
  }
}
