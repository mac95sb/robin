@_spi(Rendering) import RobinCore
import RobinHTML

public enum FlexDirection: String, Sendable {
  case row
  case rowReverse = "row-reverse"
  case column
  case columnReverse = "column-reverse"
}
public enum FlexWrap: String, Sendable {
  case noWrap = "nowrap"
  case wrap
  case reverse = "wrap-reverse"
}
public enum Justification: String, Sendable {
  case start = "flex-start"
  case center
  case end = "flex-end"
  case spaceBetween = "space-between"
  case spaceAround = "space-around"
  case spaceEvenly = "space-evenly"
}
public enum Alignment: String, Sendable {
  case stretch
  case start = "flex-start"
  case center
  case end = "flex-end"
  case baseline
}
public enum GridFlow: String, Sendable {
  case row, column
  case dense = "row dense"
}

extension Component {
  public func flex(
    direction: FlexDirection = .row,
    wrap: FlexWrap = .noWrap,
    justify: Justification = .start,
    align: Alignment = .stretch,
    gap: SpacingToken? = nil,
    on condition: Condition = .always
  ) -> some Component {
    var declarations = [
      styled(.display, .keyword("flex"), on: condition),
      styled(.flexDirection, .keyword(direction.rawValue), on: condition),
      styled(.flexWrap, .keyword(wrap.rawValue), on: condition),
      styled(.justifyContent, .keyword(justify.rawValue), on: condition),
      styled(.alignItems, .keyword(align.rawValue), on: condition),
    ]
    if let gap { declarations.append(styled(.gap, .spacing(gap.rawValue), on: condition)) }
    return StyledComponent(content: self, declarations: declarations)
  }

  public func flexItem(
    order: Int = 0,
    grow: Int = 0,
    shrink: Int = 1,
    basis: Int? = nil,
    on condition: Condition = .always
  ) -> some Component {
    var declarations = [
      styled(.order, .number(order), on: condition),
      styled(.flexGrow, .number(grow), on: condition),
      styled(.flexShrink, .number(shrink), on: condition),
    ]
    if let basis { declarations.append(styled(.flexBasis, .pixels(basis), on: condition)) }
    return StyledComponent(content: self, declarations: declarations)
  }

  public func grid(
    columns: Int,
    rows: Int? = nil,
    flow: GridFlow = .row,
    gap: SpacingToken? = nil,
    on condition: Condition = .always
  ) -> some Component {
    var declarations = [
      styled(.display, .keyword("grid"), on: condition),
      styled(
        .gridTemplateColumns, .keyword("repeat(\(max(columns, 1)),minmax(0,1fr))"), on: condition),
      styled(.gridAutoFlow, .keyword(flow.rawValue), on: condition),
    ]
    if let rows {
      declarations.append(
        styled(.gridTemplateRows, .keyword("repeat(\(max(rows, 1)),minmax(0,1fr))"), on: condition))
    }
    if let gap { declarations.append(styled(.gap, .spacing(gap.rawValue), on: condition)) }
    return StyledComponent(content: self, declarations: declarations)
  }

  public func gridItem(column: Int? = nil, row: Int? = nil, on condition: Condition = .always)
    -> some Component
  {
    var declarations: [StyleDeclaration] = []
    if let column { declarations.append(styled(.gridColumn, .number(column), on: condition)) }
    if let row { declarations.append(styled(.gridRow, .number(row), on: condition)) }
    return StyledComponent(content: self, declarations: declarations)
  }

  public func margin(_ spacing: SpacingToken, on condition: Condition = .always) -> some Component {
    StyledComponent(
      content: self, declarations: [styled(.margin, .spacing(spacing.rawValue), on: condition)])
  }

  public func frame(
    width: Int? = nil, minWidth: Int? = nil, maxWidth: Int? = nil,
    height: Int? = nil, minHeight: Int? = nil, maxHeight: Int? = nil,
    on condition: Condition = .always
  ) -> some Component {
    let pairs: [(StyleProperty, Int?)] = [
      (.width, width), (.minWidth, minWidth), (.maxWidth, maxWidth),
      (.height, height), (.minHeight, minHeight), (.maxHeight, maxHeight),
    ]
    return StyledComponent(
      content: self,
      declarations: pairs.compactMap { property, value in
        value.map { styled(property, .pixels($0), on: condition) }
      }
    )
  }

  public func aspectRatio(_ width: Int, _ height: Int, on condition: Condition = .always)
    -> some Component
  {
    StyledComponent(
      content: self,
      declarations: [
        styled(.aspectRatio, .keyword("\(max(width, 1)) / \(max(height, 1))"), on: condition)
      ])
  }
}
