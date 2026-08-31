import RobinCore
@_spi(Rendering) import RobinHTML
import Testing

private struct TestRoute: ApplicationRoute {
  let applicationRouteIdentifier = "test"
  let isAPIRoute = false
}

private struct APIOnlyApplication: Application {
  var metadata: Metadata { Metadata(title: "API") }
  var routes: some Routes { TestRoute() }
}

@Test func applicationWithRoutesInfersAPIMode() throws {
  #expect(try APIOnlyApplication().mode == .api)
}

@Test func clientNavigationIsRejectedForAPIApplications() {
  struct App: Application {
    var metadata: Metadata { Metadata() }
    var clientNavigation: ClientNavigation { .enabled }
    var routes: some Routes { TestRoute() }
  }

  #expect(
    throws: ApplicationCompositionError.clientNavigationRequiresStaticSite(.api)
  ) {
    try App().clientNavigationRuntime
  }
}
