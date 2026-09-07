@_spi(Rendering) import RobinCore
import RobinHTML

extension Component {
  /// Lays out child content with CSS flexbox.
  ///
  /// Flexbox arranges items along a main axis. Justification distributes free space on that axis; alignment acts across it. Gap separates items without adding outer padding.
  ///
  /// CSS reference: [MDN: display](https://developer.mozilla.org/en-US/docs/Web/CSS/Reference/Properties/display).
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
  /// Grow shares positive free space; shrink distributes a size deficit using each item’s basis. Visual order does not change reading or keyboard focus order.
  ///
  /// CSS reference: [MDN: flex](https://developer.mozilla.org/en-US/docs/Web/CSS/Reference/Properties/flex).
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
  /// Grid arranges items in rows and columns. Gap creates gutters between tracks, not space around the outside of the grid.
  ///
  /// CSS reference: [MDN: grid](https://developer.mozilla.org/en-US/docs/Web/CSS/Reference/Properties/grid).
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
  /// Margin adds space outside the border. Vertical margins can collapse in normal block flow, unlike padding or flex/grid gaps.
  ///
  /// CSS reference: [MDN: margin](https://developer.mozilla.org/en-US/docs/Web/CSS/Reference/Properties/margin).
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
  /// Width and height sizing follows the element’s box-sizing rule. Minimum and maximum constraints can limit the requested size.
  ///
  /// CSS reference: [MDN: width](https://developer.mozilla.org/en-US/docs/Web/CSS/Reference/Properties/width).
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
  /// A preferred aspect ratio influences automatic sizing; setting both dimensions explicitly can override its visible effect.
  ///
  /// CSS reference: [MDN: aspect-ratio](https://developer.mozilla.org/en-US/docs/Web/CSS/Reference/Properties/aspect-ratio).
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
