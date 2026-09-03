import RobinCore
@_spi(Rendering) import RobinHTML
import Testing

@Suite("App")
struct AppTests {
  @Test func appWithPagesInfersStaticMode() throws {
    struct TestApp: App {
      var metadata: Metadata { Metadata() }
      var pages: some Pages { HomePage() }
    }

    #expect(try TestApp().mode == .static)
  }

  @Test func appWithNoPagesThrowsCompositionError() {
    struct TestApp: App {
      var metadata: Metadata { Metadata() }
    }

    #expect(throws: ApplicationCompositionError.empty) {
      try TestApp().mode
    }
  }

  @Test func clientNavigationDefaultsToAutomatic() {
    struct TestApp: App {
      var metadata: Metadata { Metadata() }
      var pages: some Pages { HomePage() }
    }

    #expect(TestApp().clientNavigation == .automatic)
  }

  @Test func enabledStaticNavigationProducesCapabilityScopedRuntime() throws {
    struct TestApp: App {
      var metadata: Metadata { Metadata() }
      var clientNavigation: ClientNavigation { .enabled }
      var pages: some Pages { HomePage() }
    }

    let module = try #require(try TestApp().clientNavigationRuntime)
    #expect(module.contains("fetch(url"))
    #expect(module.contains("history.pushState"))
    #expect(module.contains("document.startViewTransition"))
    #expect(module.contains("popstate"))
    #expect(module.contains("link[data-robin-style]"))
    #expect(module.contains("copy.onload"))
  }

  @Test func pagesBuilderCollectsMultiplePagesInSourceOrder() throws {
    struct TestApp: App {
      var metadata: Metadata { Metadata() }
      var pages: some Pages {
        HomePage()
        AboutPage()
      }
    }

    let pages = TestApp().pages.pages

    #expect(pages.count == 2)
  }
}

private struct HomePage: Page {
  let path = "/"
  var body: ComponentContent { Text { "Home" } }
}

private struct AboutPage: Page {
  let path = "/about"
  var body: ComponentContent { Text { "About" } }
}
