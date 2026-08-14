/// The deployment and rendering strategy inferred from an application's registered surface.
enum ApplicationMode: Sendable {
  case `static`, ssr, api

  init(hasViews: Bool, hasControllers: Bool) throws {
    switch (hasViews, hasControllers) {
    case (true, false):
      self = .static
    case (false, true):
      self = .api
    case (true, true):
      self = .ssr
    case (false, false):
      throw ApplicationCompositionError.empty
    }
  }
}
