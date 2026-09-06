import RobinHTML
import RobinRouting
import RobinServer

struct MessageController: Controller {
  @RoutesBuilder var body: RouteList { GetMessage() }

  private struct GetMessage: Endpoint {
    let route = "message"

    func handle(_: Void, request _: EmptyRequest, context _: RequestContext) -> Message {
      Message(text: "Hello, world!")
    }
  }
}
