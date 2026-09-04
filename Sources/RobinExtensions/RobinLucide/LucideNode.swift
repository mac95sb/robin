@_spi(Rendering) import RobinHTML

enum LucideNode: Sendable {
  case circle(cx: String, cy: String, r: String, fill: String? = nil)
  case ellipse(cx: String, cy: String, rx: String, ry: String)
  case line(x1: String, y1: String, x2: String, y2: String)
  case path(String)
  case polygon(String)
  case polyline(String)
  case rect(
    x: String, y: String, width: String, height: String, rx: String?, ry: String?
  )

  var renderNode: RenderNode {
    switch self {
    case .circle(let cx, let cy, let r, let fill):
      .element(
        .init(
          kind: .circle,
          attributes: [
            .vectorCenterX(cx), .vectorCenterY(cy), .vectorRadius(r),
          ] + optional(RenderElement.Attribute.vectorFill, fill)))
    case .ellipse(let cx, let cy, let rx, let ry):
      .element(
        .init(
          kind: .ellipse,
          attributes: [
            .vectorCenterX(cx), .vectorCenterY(cy), .vectorRadiusX(rx), .vectorRadiusY(ry),
          ]))
    case .line(let x1, let y1, let x2, let y2):
      .element(
        .init(
          kind: .line,
          attributes: [.vectorX1(x1), .vectorY1(y1), .vectorX2(x2), .vectorY2(y2)]))
    case .path(let value):
      .element(.init(kind: .path, attributes: [.vectorPath(value)]))
    case .polygon(let value):
      .element(.init(kind: .polygon, attributes: [.vectorPoints(value)]))
    case .polyline(let value):
      .element(.init(kind: .polyline, attributes: [.vectorPoints(value)]))
    case .rect(let x, let y, let width, let height, let rx, let ry):
      .element(
        .init(
          kind: .rect,
          attributes: [
            .vectorX(x), .vectorY(y), .vectorWidth(width), .vectorHeight(height),
          ] + optional(RenderElement.Attribute.vectorRadiusX, rx)
            + optional(RenderElement.Attribute.vectorRadiusY, ry)))
    }
  }
}

private func optional(
  _ attribute: (String) -> RenderElement.Attribute,
  _ value: String?
) -> [RenderElement.Attribute] {
  value.map { [attribute($0)] } ?? []
}
