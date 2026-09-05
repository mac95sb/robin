import Foundation
import HTTPTypes
import RobinBuild
import RobinCore
import RobinForms
@_spi(Rendering) import RobinHTML
import RobinRouting
@_spi(Rendering) import RobinStyle
import ServiceContextModule
import Tracing

/// Executes routing and middleware without assuming a listener, channel, or deployment runtime.
public struct ApplicationResponder: Sendable {
  private let routes: [any ServerRoute]
  private let middleware: [Middleware]
  private let api: APIConfiguration
  private let errorResponses: ErrorResponses

  /// Creates a responder from executable server routes.
  ///
  /// - Parameters:
  ///   - routes: Routes available to the responder.
  ///   - api: The prefix and versioning policy for API routes.
  ///   - middleware: Middleware applied in array order.
  ///   - errorResponses: Application-specific 404 and 500 response rendering.
  ///   - transportCapabilities: Features supported by the selected transport.
  /// - Throws: A route conflict or missing transport capability diagnostic.
  public init(
    routes: [any ServerRoute],
    api: APIConfiguration = .default,
    middleware: [Middleware] = [],
    errorResponses: ErrorResponses = .init(),
    transportCapabilities: TransportCapabilities
  ) throws {
    _ = try RouteRegistry(routes, api: api)
    self.routes = routes
    let requiredCapabilities = routes.reduce(into: TransportCapabilities()) {
      $0.formUnion($1.requiredCapabilities)
    }.union(
      middleware.reduce(into: TransportCapabilities()) { $0.formUnion($1.requiredCapabilities) })
    if !transportCapabilities.isSuperset(of: requiredCapabilities) {
      throw TransportCapabilityError(
        required: requiredCapabilities,
        available: transportCapabilities
      )
    }
    self.middleware = middleware
    self.api = api
    self.errorResponses = errorResponses
  }

  /// Creates a responder from an application's pages and controller routes.
  ///
  /// - Parameters:
  ///   - application: The application whose registrations should be served.
  ///   - api: The prefix and versioning policy for API routes.
  ///   - middleware: Middleware applied in array order.
  ///   - errorResponses: Application-specific 404 and 500 response rendering.
  ///   - transportCapabilities: Features supported by the selected transport.
  /// - Throws: A route conflict, unsupported route, or missing transport capability diagnostic.
  public init<Application: App>(
    _ application: Application,
    api: APIConfiguration = .default,
    middleware: [Middleware] = [],
    errorResponses: ErrorResponses = .init(),
    transportCapabilities: TransportCapabilities
  ) throws {
    let pageRegistrations = application.pages.pages
    let pages: [any ServerRoute]
    if pageRegistrations.isEmpty {
      pages = []
    } else {
      let theme: Theme
      if let configured = application.theme as? Theme {
        theme = configured
      } else if application.theme is DefaultApplicationTheme {
        theme = .default
      } else {
        throw BuildError.unsupportedTheme
      }
      pages = pageRegistrations.map {
        RegisteredPageRoute($0, metadata: application.metadata, theme: theme)
      }
    }
    let routes: [any ServerRoute] = try flattenedApplicationRoutes(application.routes.routes).map {
      registration in
      guard let route = registration.route as? any ServerRoute else {
        throw RouteRegistryError.unsupportedRoute(registration.route.applicationRouteIdentifier)
      }
      guard !registration.prefixes.isEmpty else { return route }
      let prefixes = try registration.prefixes.flatMap { prefix in
        guard let segments = routeGroupPathSegments(in: prefix) else {
          throw RouteRegistryError.invalidGroup(prefix)
        }
        return segments
      }
      return try GroupedServerRoute(route, prefixes: prefixes)
    }
    try self.init(
      routes: pages + routes,
      api: api,
      middleware: middleware,
      errorResponses: errorResponses,
      transportCapabilities: transportCapabilities
    )
  }

  /// Produces a response without assuming a listener or channel.
  ///
  /// Handler errors become safe HTTP responses. When `context` is omitted, the responder creates
  /// a request identifier.
  ///
  /// - Parameters:
  ///   - request: The normalized request to execute.
  ///   - context: Existing request-scoped values supplied by the transport.
  /// - Returns: The matched response, a safe error response, or a 404 response.
  public func respond(
    to request: Request,
    context: RequestContext? = nil
  ) async -> Response {
    let context = context ?? RequestContext(requestID: UUID().uuidString.lowercased())
    return await ServiceContext.withValue(context.serviceContext) {
      await withSpan(
        "HTTP \(request.method.rawValue)", context: context.serviceContext, ofKind: .server
      ) { _ in
        do {
          return try await run(0, request: request, context: context)
        } catch let error as ServerError {
          return errorResponse(
            error.publicMessage,
            status: error.status,
            headers: error.headers,
            representation: error.preferredRepresentation,
            request: request,
            context: context
          )
        } catch is FieldValidationError, is MultipartError {
          return errorResponse(
            "Invalid form submission", status: .badRequest, request: request, context: context)
        } catch is CancellationError {
          return errorResponse(
            "Request cancelled", status: HTTPResponse.Status(code: 499), request: request,
            context: context)
        } catch {
          return errorResponses.internalServerError(request, context)
        }
      }
    }
  }

  private func run(
    _ index: Int,
    request: Request,
    context: RequestContext
  ) async throws -> Response {
    try await ServiceContext.withValue(context.serviceContext) {
      guard index < middleware.count else {
        for route in routes {
          if let response = try await route.respond(to: request, context: context, api: api) {
            return response
          }
        }
        return errorResponses.notFound(request, context)
      }

      return try await middleware[index].respond(
        to: request,
        context: context,
        next: .init { request, context in
          try await run(index + 1, request: request, context: context)
        }
      )
    }
  }

  private func errorResponse(
    _ message: String,
    status: HTTPResponse.Status,
    headers: HTTPFields = [:],
    representation: ServerErrorRepresentation = .automatic,
    request: Request,
    context: RequestContext
  ) -> Response {
    let wantsJSON =
      representation == .json
      || (representation == .automatic
        && request.header(.accept)?.lowercased().contains("application/json") == true)
    var response: Response
    if wantsJSON {
      response =
        (try? .json(
          ErrorResponse(error: message, requestID: context.requestID),
          status: status
        )) ?? .text(message, status: status)
    } else {
      response = .text(message, status: status)
    }
    for field in headers { response.head.headerFields[field.name] = field.value }
    return response
  }
}

private struct GroupedServerRoute: APIRoute, ServerRoute {
  let route: any ServerRoute
  let prefixes: [String]
  let method: HTTPMethod
  let version: Version?

  init(_ route: any ServerRoute, prefixes: [String]) throws {
    guard let apiRoute = route as? any APIRoute else {
      throw RouteRegistryError.unsupportedRoute(route.applicationRouteIdentifier)
    }
    self.route = route
    self.prefixes = prefixes
    self.method = apiRoute.method
    self.version = apiRoute.version
  }

  var metadata: RouteMetadata { route.metadata }
  var pattern: RoutePattern {
    RoutePattern(prefixes.map(RoutePattern.Segment.literal) + route.pattern.segments)
  }
  var requiredCapabilities: TransportCapabilities { route.requiredCapabilities }

  func respond(
    to request: Request,
    context: RequestContext,
    api: APIConfiguration
  ) async throws -> Response? {
    let apiPrefix = api.root.value + (version.map { "/v\($0.number)" } ?? "")
    let groupPrefix = "/" + prefixes.joined(separator: "/")
    let prefix = apiPrefix + groupPrefix
    guard request.path == prefix || request.path.hasPrefix(prefix + "/") else { return nil }

    var head = request.head
    head.path = apiPrefix + request.target.dropFirst(prefix.count)
    return try await route.respond(
      to: Request(head, body: request.body),
      context: context,
      api: api
    )
  }
}

private struct RegisteredPageRoute: ServerRoute {
  let path: String
  let metadata = RouteMetadata()
  private let render: @Sendable () throws -> Response
  let requiredCapabilities: TransportCapabilities = []

  init(_ page: any Page, metadata: Metadata, theme: Theme) {
    precondition(page.path.first == "/")
    self.path = page.path
    self.render = {
      try Response.html(metadata: metadata.merging(page: page.metadata), theme: theme) {
        page.body
      }
    }
  }

  var pattern: RoutePattern {
    RoutePattern(path.split(separator: "/").map { .literal(String($0)) })
  }

  func respond(
    to request: Request,
    context: RequestContext,
    api: APIConfiguration
  ) async throws -> Response? {
    guard request.method == .get else { return nil }
    guard request.path == path else { return nil }
    return try render()
  }
}

private struct ErrorResponse: Encodable, Sendable {
  let error: String
  let requestID: String
}
