import OrderedCollections

/// Compiles typed declarations into deterministic, deduplicated CSS.
public enum TypedCSSCompiler {
  /// Compiles styles while preserving an input class name for each style.
  ///
  /// Each style is normalized (later values win per property) and assigned a
  /// stable `r-`-prefixed class name derived from a hash of its canonical text,
  /// so equal styles share a class. Rules in the emitted stylesheet are sorted
  /// by class name to keep output deterministic.
  ///
  /// - Parameter styles: The styles to compile, in order.
  /// - Returns: The generated class names (one per input style, in order) and
  ///   the deduplicated stylesheet.
  public static func compile(_ styles: [TypedStyle]) -> CompiledStyles {
    var rules: OrderedDictionary<String, [StyleDeclaration]> = [:]
    var classNames: [String] = []

    for style in styles {
      let declarations = style.normalized
      let canonical = declarations.map { "\($0.property.rawValue):\($0.value)" }.joined(
        separator: ";")
      let className = "r-\(stableHash(canonical))"
      rules[className] = declarations
      classNames.append(className)
    }

    let css = rules.keys.sorted().map { name in
      let body = rules[name, default: []]
        .map { "\($0.property.rawValue):\($0.value)" }
        .joined(separator: ";")
      return ".\(name){\(body)}"
    }.joined(separator: "\n")

    return CompiledStyles(classNames: classNames, css: css)
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
