import Foundation
@_spi(Rendering) import RobinCore
@_spi(Rendering) import RobinHTML

/// Compiles typed Render IR styles into deterministic CSS.
///
/// The compiler operates only on style signatures reachable from the supplied
/// render tree. Theme tokens are resolved during compilation, so the generated
/// stylesheet contains concrete CSS values rather than token names.
public enum StyleCompiler {
  /// Compiles every nonempty element style signature reachable from a render tree.
  ///
  /// Compilation proceeds through these stages:
  ///
  /// 1. Traverse elements and fragments and collect each
  ///    element's complete, nonempty style signature.
  /// 2. Normalize each signature so the last declaration for a given CSS
  ///    property and condition wins, then sort the surviving declarations by
  ///    layer, condition, and property.
  /// 3. Deduplicate equal normalized signatures and resolve their color,
  ///    typography, spacing, radius, and breakpoint tokens against `theme`.
  ///    Colors under ``Condition/dark`` resolve from ``Theme/darkColors``;
  ///    all other color declarations resolve from ``Theme/lightColors``.
  /// 4. Deduplicate signatures that become identical after token resolution and derive each class
  ///    name from a stable hash of the resolved signature.
  /// 5. Emit rules globally in base, responsive, state, and mode order, with class names as the
  ///    deterministic tie breaker, then join them using `mode`'s whitespace format.
  ///
  /// Repeated normalized signatures share one class assignment. An element with
  /// no styles produces no assignment or CSS rule.
  ///
  /// - Parameters:
  ///   - root: The resolved Render IR tree whose reachable styles are compiled.
  ///   - theme: The design-token values used to resolve declarations and
  ///     tokenized minimum-width conditions.
  ///   - mode: The whitespace formatting to use for the emitted stylesheet.
  /// - Returns: The deterministic class assignments and emitted stylesheet.
  /// - Throws: A ``ThemeError`` when a collected declaration or condition
  ///   references a token absent from the applicable theme dictionary.
  public static func compile(
    _ root: RobinHTML.RenderNode,
    theme: Theme,
    mode: CSSOutputMode,
    animations: [KeyframeAnimation] = [],
    viewTransitions: ViewTransitionNavigation = .disabled
  ) throws -> CompiledStyles {
    let signatures = try collect(from: root, hasContainmentAncestor: false)
    var resolvedBySignature: [[StyleDeclaration]: ResolvedSignature] = [:]

    for signature in signatures {
      let normalized = normalized(signature)
      if resolvedBySignature[normalized] == nil {
        resolvedBySignature[normalized] = try resolve(normalized, theme: theme)
      }
    }

    let resolvedGroups = Dictionary(grouping: resolvedBySignature.keys) {
      resolvedBySignature[$0]!.canonical
    }
    let ordered = resolvedGroups.map { canonical, signatures in
      let signatures = signatures.sorted {
        canonicalSourceSignature($0) < canonicalSourceSignature($1)
      }
      let resolved = resolvedBySignature[signatures[0]]!
      return (
        canonical: canonical,
        signatures: signatures,
        resolved: resolved,
        className: "r1-\(CSSSerialization.stableHash(canonical))"
      )
    }.sorted {
      ($0.className, $0.canonical) < ($1.className, $1.canonical)
    }

    var owners: [String: String] = [:]
    for group in ordered {
      if let owner = owners[group.className], owner != group.canonical {
        throw StyleCompilerError.selectorCollision(group.className)
      }
      owners[group.className] = group.canonical
    }

    let separator = mode == .development ? "\n" : ""
    let rules = ordered.flatMap { group in
      group.resolved.rules(className: group.className, mode: mode)
    }.sorted(by: ruleOrder).map(\.css)
    let keyframes = Dictionary(grouping: animations, by: \.name).values.compactMap(\.first)
      .sorted { $0.name < $1.name }.map(\.css)
    let viewTransitionCSS =
      viewTransitions == .enabled ? "@view-transition{navigation:auto}" : nil
    let css = (rules + keyframes + [viewTransitionCSS].compactMap { $0 }).joined(
      separator: separator)

    return CompiledStyles(
      assignments: ordered.flatMap { group in
        group.signatures.map { .init(signature: $0, className: group.className) }
      },
      css: css
    )
  }

  static func normalized(
    _ styles: [StyleDeclaration]
  ) -> [StyleDeclaration] {
    var declarations: [DeclarationKey: InterpretedStyle] = [:]
    for style in styles {
      let interpreted = InterpretedStyle(style)
      declarations[
        .init(property: interpreted.property, condition: interpreted.condition)
      ] = interpreted
    }
    return declarations.values.sorted(by: declarationOrder).map(\.source)
  }

  private static func collect(
    from node: RobinHTML.RenderNode,
    hasContainmentAncestor: Bool
  ) throws -> [[StyleDeclaration]] {
    switch node.renderingStorage {
    case .text: return []
    case .fragment(let children):
      return try children.flatMap {
        try collect(from: $0, hasContainmentAncestor: hasContainmentAncestor)
      }
    case .element(let element):
      if !hasContainmentAncestor,
        element.styles.contains(where: {
          $0.condition.hasPrefix("container-minimum-width-token:")
        })
      {
        throw ThemeError.missingContainmentAncestor
      }
      let declaresContainment = element.styles.contains {
        $0.property == StyleProperty.containerType.rawValue
          && $0.payload != .keyword(ContainerType.normal.rawValue)
      }
      return (element.styles.isEmpty ? [] : [element.styles])
        + (try element.children.flatMap {
          try collect(
            from: $0,
            hasContainmentAncestor: hasContainmentAncestor || declaresContainment)
        })
    }
  }

  private static func resolve(
    _ styles: [StyleDeclaration],
    theme: Theme
  ) throws -> ResolvedSignature {
    try .init(
      declarations: styles.map { source in
        let style = InterpretedStyle(source)
        return ResolvedDeclaration(
          property: style.property,
          value: try resolve(style.value, condition: style.condition, theme: theme),
          condition: try resolve(style.condition, theme: theme)
        )
      })
  }

  private static func resolve(
    _ value: StyleValue,
    condition: StyleCondition,
    theme: Theme
  ) throws -> String {
    switch value {
    case .keyword(let value): return value
    case .color(let name):
      let token = ColorToken(rawValue: name)
      let palette = condition == .dark ? theme.darkColors : theme.lightColors
      guard let color = palette[token] else { throw ThemeError.missingColor(token) }
      return serialize(color)
    case .spacing(let name):
      let token = SpacingToken(rawValue: name)
      guard let value = theme.spacing[token] else { throw ThemeError.missingSpacing(token) }
      return "\(value)px"
    case .radius(let name):
      let token = RadiusToken(rawValue: name)
      guard let value = theme.radii[token] else { throw ThemeError.missingRadius(token) }
      return "\(value)px"
    case .fontFamily(let name):
      let token = TypographyToken(rawValue: name)
      guard let value = theme.typography[token] else { throw ThemeError.missingTypography(token) }
      return "\"\(escapeCSSString(value.family))\""
    case .fontSize(let name):
      let token = TypographyToken(rawValue: name)
      guard let value = theme.typography[token] else { throw ThemeError.missingTypography(token) }
      return "\(value.size)px"
    case .fontWeight(let value): return String(value)
    case .fontWeightToken(let name):
      let token = TypographyToken(rawValue: name)
      guard let typography = theme.typography[token] else {
        throw ThemeError.missingTypography(token)
      }
      return String(typography.weight)
    case .pixels(let value): return "\(max(value, 0))px"
    case .number(let value): return String(value)
    case .shadow(let name):
      let token = ShadowToken(rawValue: name)
      guard let shadow = theme.shadows[token] else { throw ThemeError.missingShadow(token) }
      return "\(shadow.x)px \(shadow.y)px \(max(shadow.radius, 0))px \(serialize(shadow.color))"
    }
  }

  private static func resolve(
    _ condition: StyleCondition,
    theme: Theme
  ) throws -> ResolvedCondition {
    switch condition {
    case .always:
      return .always
    case .minimumWidth(let width):
      return .minimumWidth(width)
    case .minimumWidthToken(let name):
      let token = BreakpointToken(rawValue: name)
      guard let width = theme.breakpoints[token] else { throw ThemeError.missingBreakpoint(token) }
      return .minimumWidth(width)
    case .hover:
      return .hover
    case .focus:
      return .focus
    case .dark:
      return .dark
    case .expression(let value):
      let resolved = try ConditionExpression.parse(value).resolve(theme: theme)
      return .expression(media: resolved.media, selector: resolved.selector)
    case .containerMinimumWidthToken(let name):
      let token = BreakpointToken(rawValue: name)
      guard let width = theme.breakpoints[token] else { throw ThemeError.missingBreakpoint(token) }
      return .containerMinimumWidth(width)
    case .startingStyle:
      return .startingStyle
    }
  }

  private static func serialize(_ color: Color) -> String {
    let lightness = CSSSerialization.decimal(color.lightness)
    let chroma = CSSSerialization.decimal(color.chroma)
    let hue = CSSSerialization.decimal(color.hue)
    if color.alpha == 1 { return "oklch(\(lightness) \(chroma) \(hue))" }
    return "oklch(\(lightness) \(chroma) \(hue) / \(CSSSerialization.decimal(color.alpha)))"
  }

  private static func escapeCSSString(_ value: String) -> String {
    var escaped = ""
    for scalar in value.unicodeScalars {
      switch scalar {
      case "\\": escaped += "\\\\"
      case "\"": escaped += "\\\""
      case "\n": escaped += "\\A "
      case "\r": escaped += "\\D "
      case "\u{000C}": escaped += "\\C "
      default:
        if scalar.value < 0x20 || scalar.value == 0x7F {
          escaped += "\\\(String(scalar.value, radix: 16).uppercased()) "
        } else {
          escaped.unicodeScalars.append(scalar)
        }
      }
    }
    return escaped
  }

  private static func ruleOrder(_ lhs: ResolvedRule, _ rhs: ResolvedRule) -> Bool {
    if lhs.condition != rhs.condition {
      return lhs.condition < rhs.condition
    }
    return lhs.className < rhs.className
  }

  private static func declarationOrder(_ lhs: InterpretedStyle, _ rhs: InterpretedStyle) -> Bool {
    let left = (lhs.condition.layer.rawValue, lhs.condition.sortKey, lhs.property.rawValue)
    let right = (rhs.condition.layer.rawValue, rhs.condition.sortKey, rhs.property.rawValue)
    return left < right
  }

  private static func canonicalSourceSignature(
    _ signature: [StyleDeclaration]
  ) -> String {
    signature.map { declaration in
      let payload =
        switch declaration.payload {
        case .keyword(let value): "keyword:\(field(value))"
        case .token(let value): "token:\(field(value))"
        case .integer(let value): "integer:\(value)"
        }
      return "\(field(declaration.property))\(field(payload))\(field(declaration.condition))"
    }.joined()
  }

  private static func field(_ value: String) -> String {
    "\(value.utf8.count):\(value)"
  }

}

enum CSSSerialization {
  static func decimal(_ value: Double) -> String {
    String(format: "%.4f", locale: Locale(identifier: "en_US_POSIX"), value)
      .replacingOccurrences(of: #"0+$"#, with: "", options: .regularExpression)
      .replacingOccurrences(of: #"\.$"#, with: "", options: .regularExpression)
  }

  static func stableHash(_ value: String) -> String {
    var hash: UInt64 = 14_695_981_039_346_656_037
    for byte in value.utf8 {
      hash ^= UInt64(byte)
      hash &*= 1_099_511_628_211
    }
    return String(hash, radix: 36)
  }
}

private struct DeclarationKey: Hashable {
  let property: StyleProperty
  let condition: StyleCondition
}

private struct ResolvedSignature {
  let declarations: [ResolvedDeclaration]
  var canonical: String { declarations.map(\.canonical).joined(separator: ";") }

  func rules(className: String, mode: CSSOutputMode) -> [ResolvedRule] {
    Dictionary(grouping: declarations, by: \.condition).map { condition, declarations in
      let space = mode == .development ? " " : ""
      let newline = mode == .development ? "\n" : ""
      let body = declarations.map { "\($0.property.rawValue):\(space)\($0.value);" }
        .joined(separator: newline)
      let selector = condition.selector(className: className)
      let rule =
        mode == .development
        ? "\(selector) {\n\(body)\n}"
        : "\(selector){\(body)}"
      return ResolvedRule(
        className: className,
        condition: condition,
        css: condition.wrap(rule)
      )
    }
  }
}

private struct ResolvedRule {
  let className: String
  let condition: ResolvedCondition
  let css: String
}

private struct ResolvedDeclaration {
  let property: StyleProperty
  let value: String
  let condition: ResolvedCondition
  var canonical: String { "\(condition.key)|\(property.rawValue):\(value)" }
}

private enum ResolvedCondition: Hashable, Comparable {
  case always
  case minimumWidth(Int)
  case hover
  case focus
  case dark
  case expression(media: String?, selector: String)
  case containerMinimumWidth(Int)
  case startingStyle

  var key: String {
    switch self {
    case .always: "0"
    case .minimumWidth(let width): "1:\(width)"
    case .hover: "2:hover"
    case .focus: "2:focus"
    case .dark: "3:dark"
    case .expression(let media, let selector): "2:\(media ?? ""):\(selector)"
    case .containerMinimumWidth(let width): "1:container:\(width)"
    case .startingStyle: "2:starting-style"
    }
  }

  static func < (lhs: Self, rhs: Self) -> Bool {
    switch (lhs, rhs) {
    case (.always, .always), (.hover, .hover), (.focus, .focus), (.dark, .dark): false
    case (.minimumWidth(let lhsWidth), .minimumWidth(let rhsWidth)): lhsWidth < rhsWidth
    case (.expression(let lhsMedia, let lhsSelector), .expression(let rhsMedia, let rhsSelector)):
      (lhsMedia ?? "", lhsSelector) < (rhsMedia ?? "", rhsSelector)
    case (.containerMinimumWidth(let lhsWidth), .containerMinimumWidth(let rhsWidth)):
      lhsWidth < rhsWidth
    default: lhs.rank < rhs.rank
    }
  }

  private var rank: Int {
    switch self {
    case .always: 0
    case .minimumWidth: 1
    case .focus: 2
    case .hover: 3
    case .dark: 4
    case .expression: 2
    case .containerMinimumWidth: 1
    case .startingStyle: 2
    }
  }

  func selector(className: String) -> String {
    switch self {
    case .hover: ".\(className):hover"
    case .focus: ".\(className):focus"
    case .expression(_, let selector): ".\(className)\(selector)"
    default: ".\(className)"
    }
  }

  func wrap(_ rule: String) -> String {
    switch self {
    case .minimumWidth(let width): "@media (min-width:\(width)px){\(rule)}"
    case .dark: "@media (prefers-color-scheme:dark){\(rule)}"
    case .expression(let media, _): media.map { "@media \($0){\(rule)}" } ?? rule
    case .containerMinimumWidth(let width): "@container (min-width:\(width)px){\(rule)}"
    case .startingStyle: "@starting-style{\(rule)}"
    default: rule
    }
  }
}

private indirect enum ConditionExpression {
  case minimum(String)
  case maximum(String)
  case between(String, String)
  case pseudo(String)
  case has(String)
  case and(Self, Self)
  case or(Self, Self)
  case not(Self)
  case dark
  case always

  static func parse(_ source: String) throws -> Self {
    if source == "always" { return .always }
    if source == "dark" { return .dark }
    if source.hasPrefix("min:") { return .minimum(String(source.dropFirst(4))) }
    if source.hasPrefix("max:") { return .maximum(String(source.dropFirst(4))) }
    if source.hasPrefix("pseudo:") { return .pseudo(String(source.dropFirst(7))) }
    if source.hasPrefix("between:") {
      let values = source.dropFirst(8).split(separator: ":", maxSplits: 1).map(String.init)
      guard values.count == 2 else { throw ThemeError.invalidCondition(source) }
      return .between(values[0], values[1])
    }
    if source.hasPrefix("has:") {
      let rest = source.dropFirst(4)
      guard let colon = rest.firstIndex(of: ":"), let length = Int(rest[..<colon]) else {
        throw ThemeError.invalidCondition(source)
      }
      let value = String(rest[rest.index(after: colon)...])
      guard value.utf8.count == length else { throw ThemeError.invalidCondition(source) }
      return .has(value)
    }
    if source.hasPrefix("not:") { return .not(try parse(String(source.dropFirst(4)))) }
    if source.hasPrefix("and:") {
      return try parseBinary(source, prefix: "and:", combine: { .and($0, $1) })
    }
    if source.hasPrefix("or:") {
      return try parseBinary(source, prefix: "or:", combine: { .or($0, $1) })
    }
    throw ThemeError.invalidCondition(source)
  }

  private static func parseBinary(
    _ source: String,
    prefix: String,
    combine: (Self, Self) -> Self
  ) throws -> Self {
    let rest = source.dropFirst(prefix.count)
    guard let colon = rest.firstIndex(of: ":"), let length = Int(rest[..<colon]) else {
      throw ThemeError.invalidCondition(source)
    }
    let values = rest[rest.index(after: colon)...]
    guard let split = values.index(values.startIndex, offsetBy: length, limitedBy: values.endIndex)
    else {
      throw ThemeError.invalidCondition(source)
    }
    return combine(try parse(String(values[..<split])), try parse(String(values[split...])))
  }

  func resolve(theme: Theme) throws -> (media: String?, selector: String) {
    switch self {
    case .always: return (nil, "")
    case .dark: return ("(prefers-color-scheme:dark)", "")
    case .minimum(let name): return ("(min-width:\(try width(name, theme: theme))px)", "")
    case .maximum(let name): return ("(max-width:\(try width(name, theme: theme) - 1)px)", "")
    case .between(let lower, let upper):
      return (
        "(min-width:\(try width(lower, theme: theme))px) and (max-width:\(try width(upper, theme: theme) - 1)px)",
        ""
      )
    case .pseudo(let value): return (nil, ":\(value)")
    case .has(let value): return (nil, ":has(\(value))")
    case .not(let value):
      let child = try value.resolve(theme: theme)
      if let media = child.media { return ("not \(media)", child.selector) }
      return (nil, ":not(\(child.selector))")
    case .and(let lhs, let rhs):
      let left = try lhs.resolve(theme: theme)
      let right = try rhs.resolve(theme: theme)
      let media = [left.media, right.media].compactMap { $0 }.joined(separator: " and ")
      return (media.isEmpty ? nil : media, left.selector + right.selector)
    case .or(let lhs, let rhs):
      let left = try lhs.resolve(theme: theme)
      let right = try rhs.resolve(theme: theme)
      if left.media == nil, right.media == nil {
        return (nil, ":is(\(left.selector),\(right.selector))")
      }
      guard left.selector.isEmpty, right.selector.isEmpty, let lhsMedia = left.media,
        let rhsMedia = right.media
      else { throw ThemeError.invalidCondition("Mixed media/selector disjunction") }
      return ("\(lhsMedia), \(rhsMedia)", "")
    }
  }

  private func width(_ name: String, theme: Theme) throws -> Int {
    let token = BreakpointToken(rawValue: name)
    guard let width = theme.breakpoints[token] else { throw ThemeError.missingBreakpoint(token) }
    return width
  }
}
