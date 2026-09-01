import RobinCore
@_spi(Rendering) import RobinHTML
import Testing

private struct TestRoute: ApplicationRoute {
  let applicationRouteIdentifier = "test"
}

private struct APIOnlyApp: App {
  var metadata: Metadata { Metadata(title: "API") }
  var routes: some Routes { TestRoute() }
}

@Test func appWithRoutesInfersAPIMode() throws {
  #expect(try APIOnlyApp().mode == .api)
}

@Test func clientNavigationIsRejectedForAPIApplications() {
  struct TestApp: App {
    var metadata: Metadata { Metadata() }
    var clientNavigation: ClientNavigation { .enabled }
    var routes: some Routes { TestRoute() }
  }

  #expect(
    throws: ApplicationCompositionError.clientNavigationRequiresStaticSite(.api)
  ) {
    try TestApp().clientNavigationRuntime
  }
}
