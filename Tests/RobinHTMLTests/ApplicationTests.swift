import RobinCore
import RobinHTML
import Testing

@Suite("Application")
struct ApplicationTests {
  @Test func applicationWithPagesInfersStaticMode() throws {
    struct App: Application {
      var metadata: Metadata { Metadata() }
      var pages: some Pages { HomePage() }
    }

    #expect(try App().mode == .static)
  }

  @Test func applicationWithNoPagesThrowsCompositionError() {
    struct App: Application {
      var metadata: Metadata { Metadata() }
    }

    #expect(throws: ApplicationCompositionError.empty) {
      try App().mode
    }
  }

  @Test func clientNavigationDefaultsToAutomatic() {
    struct App: Application {
      var metadata: Metadata { Metadata() }
      var pages: some Pages { HomePage() }
    }

    #expect(App().clientNavigation == .automatic)
  }

  @Test func pagesBuilderCollectsMultiplePagesInSourceOrder() throws {
    struct App: Application {
      var metadata: Metadata { Metadata() }
      var pages: some Pages {
        HomePage()
        AboutPage()
      }
    }

    let pages = App().pages.pages

    #expect(pages.count == 2)
  }
}

private struct HomePage: Page {
  var body: ComponentContent { Text { "Home" } }
}

private struct AboutPage: Page {
  var body: ComponentContent { Text { "About" } }
}
