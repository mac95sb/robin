@_spi(Rendering) import RobinCore
import RobinHTML

/// The main-axis direction of a flex container.
public enum FlexDirection: String, Sendable {
  /// Places items horizontally in source order.
  case row
  /// Places items horizontally in reverse source order.
  case rowReverse = "row-reverse"
  /// Places items vertically in source order.
  case column
  /// Places items vertically in reverse source order.
  case columnReverse = "column-reverse"
}
/// The line-wrapping behavior of a flex container.
public enum FlexWrap: String, Sendable {
  /// Keeps all items on one line.
  case noWrap = "nowrap"
  /// Wraps items onto additional lines.
  case wrap
  /// Wraps items with the cross-axis order reversed.
  case reverse = "wrap-reverse"
}
/// Distribution of flex items along the main axis.
public enum Justification: String, Sendable {
  /// Packs items at the start.
  case start = "flex-start"
  /// Centers items.
  case center
  /// Packs items at the end.
  case end = "flex-end"
  /// Distributes equal space between items.
  case spaceBetween = "space-between"
  /// Distributes equal space around items.
  case spaceAround = "space-around"
  /// Distributes equal space between items and container edges.
  case spaceEvenly = "space-evenly"
}
/// Alignment of flex items along the cross axis.
public enum Alignment: String, Sendable {
  /// Stretches items across the available cross axis.
  case stretch
  /// Aligns items at the start.
  case start = "flex-start"
  /// Centers items.
  case center
  /// Aligns items at the end.
  case end = "flex-end"
  /// Aligns item text baselines.
  case baseline
}
/// The automatic placement direction of a grid container.
public enum GridFlow: String, Sendable {
  /// Places items by row.
  case row
  /// Places items by column.
  case column
  /// Fills earlier gaps while placing items by row.
  case dense = "row dense"
}

extension Component {
  /// Lays out child content with CSS flexbox.
  ///
  /// - Parameters:
  ///   - direction: The main-axis direction.
  ///   - wrap: The line-wrapping behavior.
  ///   - justify: Distribution along the main axis.
  ///   - align: Alignment along the cross axis.
  ///   - gap: Optional space between items.
  ///   - condition: The condition under which the declarations apply.
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

  /// Configures this component as an item within a flex container.
  ///
  /// - Parameters:
  ///   - order: The item's visual order.
  ///   - grow: Its positive free-space growth factor.
  ///   - shrink: Its negative free-space shrink factor.
  ///   - basis: An optional initial size in pixels.
  ///   - condition: The condition under which the declarations apply.
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

  /// Lays out child content with an equal-track CSS grid.
  ///
  /// - Parameters:
  ///   - columns: The positive number of equal columns.
  ///   - rows: An optional positive number of equal rows.
  ///   - flow: The automatic placement direction.
  ///   - gap: Optional space between tracks.
  ///   - condition: The condition under which the declarations apply.
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

  /// Places this component at explicit grid coordinates.
  ///
  /// - Parameters:
  ///   - column: An optional one-based grid column.
  ///   - row: An optional one-based grid row.
  ///   - condition: The condition under which the declarations apply.
  public func gridItem(column: Int? = nil, row: Int? = nil, on condition: Condition = .always)
    -> some Component
  {
    var declarations: [StyleDeclaration] = []
    if let column { declarations.append(styled(.gridColumn, .number(column), on: condition)) }
    if let row { declarations.append(styled(.gridRow, .number(row), on: condition)) }
    return StyledComponent(content: self, declarations: declarations)
  }

  /// Applies equal margin on every side.
  ///
  /// - Parameters:
  ///   - spacing: The theme spacing token.
  ///   - condition: The condition under which the declaration applies.
  public func margin(_ spacing: SpacingToken, on condition: Condition = .always) -> some Component {
    StyledComponent(
      content: self, declarations: [styled(.margin, .spacing(spacing.rawValue), on: condition)])
  }

  /// Constrains the component's width and height in pixels.
  ///
  /// - Parameters:
  ///   - width: An optional exact width.
  ///   - minWidth: An optional minimum width.
  ///   - maxWidth: An optional maximum width.
  ///   - height: An optional exact height.
  ///   - minHeight: An optional minimum height.
  ///   - maxHeight: An optional maximum height.
  ///   - condition: The condition under which the declarations apply.
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

  /// Applies a positive width-to-height aspect ratio.
  ///
  /// - Parameters:
  ///   - width: The width component, clamped to at least one.
  ///   - height: The height component, clamped to at least one.
  ///   - condition: The condition under which the declaration applies.
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
