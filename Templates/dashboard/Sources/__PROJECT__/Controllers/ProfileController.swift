import Foundation
import RobinCore
import RobinHTML
import RobinRouting
import RobinServer
import RobinStyle
import RobinTheme

/// Lets authenticated people choose their unique chat username.
struct ProfileController: Controller {
  let usernames: UsernameStore
  @RoutesBuilder var body: RouteList { SetUsername(usernames: usernames) }

  private struct SetUsername: APIRoute, ServerRoute {
    let usernames: UsernameStore
    let requiredCapabilities: TransportCapabilities = [.processLocalState]
    let method = HTTPMethod.post
    let version: Version? = .default
    let pattern = RoutePattern([.literal("username")])

    func respond(to request: Request, context: RequestContext, api: APIConfiguration) async throws
      -> Response?
    {
      guard request.method == .post,
        request.path == "\(api.root.value)/v\(Version.default.number)/username"
      else { return nil }
      guard let principal = context.principal else {
        throw ServerError(.unauthorized, "Sign in to choose a username.")
      }
      let proposed = request.formValue(named: "username") ?? ""
      let returnPath =
        request.header(.referer).flatMap { URL(string: $0)?.path }
        .map {
          $0 == "/fr" || $0.hasPrefix("/fr/") ? "/fr" : "/en"
        } ?? "/en"
      let destination = returnPath + "/conversations"
      do {
        try await usernames.set(proposed, for: principal.id)
      } catch let error as UsernameError {
        return try .html(
          metadata: .init(title: "Choose a username"),
          theme: .robin,
          status: error == .taken ? .conflict : .badRequest
        ) {
          DashboardPageLayout {
            Main {
              Heading { "Choose a username" }
              Text { error.message }
              UsernameEditor(username: proposed)
              DashboardLabel { Link(destination) { "Back to conversations" } }
            }
            .grid(columns: 1, gap: .md)
          }
        }
      }
      return .redirect(to: destination)
    }
  }
}
