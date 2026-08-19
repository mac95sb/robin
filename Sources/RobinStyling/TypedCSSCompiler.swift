import OrderedCollections

/// Compiles typed declarations into deterministic, deduplicated CSS.
public enum TypedCSSCompiler {
  /// Compiles styles and typed keyframe animations while preserving an input class name for each
  /// style.
  ///
  /// Each style is normalized (later values win per property) and assigned a stable
  /// `r-`-prefixed class name derived from a hash of its canonical text and condition, so equal
  /// styles under equal conditions share a class. Because every `TypedStyle` compiles to its own
  /// class independently of any other style passed alongside it, a component's base style and a
  /// composition-time instance override compile to separate, isolated selectors when passed as
  /// separate `TypedStyle` values. Rules are sorted by class name to keep output deterministic,
  /// and `@keyframes` rules are emitted after the class rules, sorted by animation name.
  ///
  /// - Parameters:
  ///   - styles: The styles to compile, in order.
  ///   - animations: The typed keyframe animations to compile, in any order.
  /// - Returns: The generated class names (one per input style, in order) and the deduplicated
  ///   stylesheet.
  /// - Throws: ``TypedCSSCompilerError/missingContainmentAncestor`` when a style conditioned on
  ///   ``StyleCondition/containerMinWidth(_:)`` has no declared containment ancestor.
  public static func compile(
    _ styles: [TypedStyle],
    animations: [KeyframeAnimation] = []
  ) throws -> CompiledStyles {
    var rules:
      OrderedDictionary<String, (declarations: [StyleDeclaration], condition: StyleCondition)> = [:]
    var classNames: [String] = []

    for style in styles {
      if case .containerMinWidth = style.condition, style.containmentContext == .none {
        throw TypedCSSCompilerError.missingContainmentAncestor
      }
      let declarations = style.normalized
      let canonical = declarations.map { "\($0.property.rawValue):\($0.value)" }.joined(
        separator: ";")
      let className = "r-\(stableHash("\(canonical)|\(style.condition.canonicalKey)"))"
      rules[className] = (declarations, style.condition)
      classNames.append(className)
    }

    let classCSS = rules.keys.sorted().map { name in
      let (declarations, condition) = rules[name]!
      let body =
        declarations
        .map { "\($0.property.rawValue):\($0.value)" }
        .joined(separator: ";")
      let rule = ".\(name){\(body)}"
      return wrap(rule, for: condition)
    }.joined(separator: "\n")

    let keyframesCSS = animations.sorted { $0.name < $1.name }.map(emit).joined(separator: "\n")

    let css = [classCSS, keyframesCSS].filter { !$0.isEmpty }.joined(separator: "\n")

    return CompiledStyles(classNames: classNames, css: css)
  }

  private static func wrap(_ rule: String, for condition: StyleCondition) -> String {
    switch condition {
    case .always:
      return rule
    case .has(let selector):
      // The relational pseudo-class is appended to the generated selector itself.
      guard let closingBrace = rule.firstIndex(of: "{") else { return rule }
      let selectorPart = rule[rule.startIndex..<closingBrace]
      let bodyPart = rule[closingBrace...]
      return "\(selectorPart):has(\(selector))\(bodyPart)"
    case .containerMinWidth(let width):
      return "@container (min-width:\(width)px){\(rule)}"
    case .pageMinWidth(let width):
      return "@media (min-width:\(width)px){\(rule)}"
    case .startingStyle:
      return "@starting-style{\(rule)}"
    }
  }

  private static func emit(_ animation: KeyframeAnimation) -> String {
    let body = animation.stops.sorted { $0.percentage < $1.percentage }.map { stop in
      let declarations = stop.declarations
        .map { "\($0.property.rawValue):\($0.value)" }
        .joined(separator: ";")
      return "\(stop.percentage)%{\(declarations)}"
    }.joined()
    return "@keyframes \(animation.name){\(body)}"
  }

  private static func stableHash(_ value: String) -> String {
    var hash: UInt64 = 14_695_981_039_346_656_037
    for byte in value.utf8 {
      hash ^= UInt64(byte)
      hash &*= 1_099_511_628_211
    }
    return String(hash, radix: 36)
  }
}
