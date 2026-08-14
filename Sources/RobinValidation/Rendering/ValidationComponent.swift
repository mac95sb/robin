public protocol ValidationComponent: Sendable {
  @RenderBuilder var body: [RenderNode] { get }
}

extension ValidationComponent {
  public func resolve() -> RenderNode { .fragment(body) }
}
