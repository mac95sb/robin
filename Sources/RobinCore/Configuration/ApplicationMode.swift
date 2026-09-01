/// The deployment and rendering strategy inferred from an application's registered surface.
///
/// The mode is derived from which halves of an application are present: views
/// without controllers render statically, controllers without views serve an
/// API, and both together render server-side on each request.
public enum ApplicationMode: Equatable, Sendable {
  /// Views with no controllers: pre-rendered static output.
  case `static`

  /// Views and controllers: server-rendered per request.
  case ssr

  /// Controllers with no views: data-only API responses.
  case api

  /// Infers the mode from an application's registered surface.
  ///
  /// - Parameters:
  ///   - hasViews: Whether the application registers any views.
  ///   - hasControllers: Whether the application registers any controllers.
  /// - Throws: ``ApplicationCompositionError/empty`` when the application
  ///   registers neither views nor controllers.
  public init(hasViews: Bool, hasControllers: Bool) throws {
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
