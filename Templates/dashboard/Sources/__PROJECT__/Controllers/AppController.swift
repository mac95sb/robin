import Foundation
import RobinCore
import RobinForms
import RobinHTML
import RobinRouting
import RobinServer
import RobinStyle

/// Serves account, health, and authenticated note endpoints.
struct AppController: Controller {
  let notes: NotesStore

  @RoutesBuilder var body: RouteList {
    RouteGroup("system") { GET(version: nil, use: health) }
    AccountEndpoint()
    ListNotes(notes: notes)
    NoteMutation(.create, notes: notes)
    NoteMutation(.update, notes: notes)
    NoteMutation(.delete, notes: notes)
  }

  private struct AccountEndpoint: Endpoint {
    let route = "account"

    func handle(_: Void, request _: EmptyRequest, context: RequestContext) throws -> AccountView {
      guard let principal = context.principal else {
        throw ServerError(.unauthorized, "Sign in to view this account.")
      }
      return AccountView(id: principal.id)
    }
  }

  private func health(_: Void, context _: RequestContext) -> Health { Health(status: "ok") }

  private struct ListNotes: Endpoint {
    let route = "notes"
    let notes: NotesStore

    func handle(_: Void, request _: EmptyRequest, context: RequestContext) async throws -> [Note] {
      guard let principal = context.principal else {
        throw ServerError(.unauthorized, "Sign in to read notes.")
      }
      return try await notes.all(ownerID: principal.id)
    }
  }

  private struct NoteMutation: APIRoute, ServerRoute {
    enum Operation { case create, update, delete }

    let operation: Operation
    let notes: NotesStore
    let method = HTTPMethod.post
    let version: Version? = .default
    let requiredCapabilities: TransportCapabilities = [.processLocalState]

    init(_ operation: Operation, notes: NotesStore) {
      self.operation = operation
      self.notes = notes
    }

    var pattern: RoutePattern {
      switch operation {
      case .create: RoutePattern([.literal("notes")])
      case .update: RoutePattern([.literal("notes"), .parameter("id")])
      case .delete: RoutePattern([.literal("notes"), .parameter("id"), .literal("delete")])
      }
    }

    func respond(
      to request: Request,
      context: RequestContext,
      api: APIConfiguration
    ) async throws -> Response? {
      guard request.method.rawValue.caseInsensitiveCompare(method.rawValue) == .orderedSame else {
        return nil
      }
      let prefix = Version.default.path(relativePath: "", api: api)
      guard request.path.hasPrefix(prefix + "/") else { return nil }
      let parts = request.path.dropFirst(prefix.count).split(separator: "/").map(String.init)
      guard parts.first == "notes" else { return nil }

      guard let principal = context.principal else {
        throw ServerError(.unauthorized, "Sign in to change notes.")
      }
      switch operation {
      case .create:
        guard parts == ["notes"] else { return nil }
        let form = try request.form(NoteForm.self)
        if let response = try invalidFormResponse(form, request: request) { return response }
        try await notes.create(form.validated().content, ownerID: principal.id)
      case .update:
        guard
          parts.count == 2,
          parts[0] == "notes",
          let id = Int(parts[1])
        else {
          return nil
        }
        let form = try request.form(NoteForm.self)
        if let response = try invalidFormResponse(form, request: request) { return response }
        try await notes.update(id, content: form.validated().content, ownerID: principal.id)
      case .delete:
        guard
          parts.count == 3,
          parts[0] == "notes",
          parts[2] == "delete",
          let id = Int(parts[1])
        else { return nil }
        try await notes.delete(id, ownerID: principal.id)
      }

      if request.header(.accept)?.contains("application/json") == true {
        return try .json(["saved": true])
      }
      return .redirect(to: notesPath(for: request))
    }

    private func notesPath(for request: Request) -> String {
      let locale = request.header(.referer).flatMap {
        URL(string: $0)?.path.split(separator: "/").first
      }
      return locale == "fr" ? "/fr/notes" : "/en/notes"
    }

    private func invalidFormResponse(_ form: NoteForm, request: Request) throws -> Response? {
      guard !form.validationErrors.isEmpty else { return nil }
      if request.header(.contentType)?.hasPrefix("application/json") == true
        || request.header(.accept)?.contains("application/json") == true
      {
        return try .json(["errors": form.validationErrors.map(\.message)], status: .badRequest)
      }
      return try .html(
        metadata: .init(title: "Check your note"), theme: .starter, status: .badRequest
      ) {
        DashboardPageLayout {
          Main {
            Heading { "Check your note" }
            NoteEditor(form: form, action: request.path, identifier: "content", button: "Save note")
            DashboardLabel { Link(notesPath(for: request)) { "Back to notes" } }
          }
        }
      }
    }
  }
}

/// The response returned by the unauthenticated readiness endpoint.
struct Health: Encodable, Sendable {
  let status: String
}

private struct AccountView: Encodable, Sendable {
  let id: String
}
