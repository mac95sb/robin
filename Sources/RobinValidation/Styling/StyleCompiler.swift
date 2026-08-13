import Foundation
import OrderedCollections

/// A CSS property supported by the typed validation compiler.
public enum StyleProperty: String, Comparable, Sendable {
  case backgroundColor = "background-color"
  case borderRadius = "border-radius"
  case color
  case display
  case fontSize = "font-size"
  case gap
  case padding

  public static func < (lhs: Self, rhs: Self) -> Bool { lhs.rawValue < rhs.rawValue }
}

/// A normalized property-value pair in a typed style.
public struct StyleDeclaration: Equatable, Hashable, Sendable {
  public let property: StyleProperty
  public let value: String

  public init(_ property: StyleProperty, _ value: String) {
    self.property = property
    self.value = value.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
  }
}

/// A collection of typed style declarations.
public struct TypedStyle: Equatable, Hashable, Sendable {
  public let declarations: [StyleDeclaration]

  public init(_ declarations: [StyleDeclaration]) {
    self.declarations = declarations
  }

  fileprivate var normalized: [StyleDeclaration] {
    var values: [StyleProperty: String] = [:]
    for declaration in declarations { values[declaration.property] = declaration.value }
    return values.map(StyleDeclaration.init).sorted { $0.property < $1.property }
  }
}

/// Deterministic class names and CSS emitted for typed styles.
public struct CompiledStyles: Equatable, Sendable {
  public let classNames: [String]
  public let css: String
}

/// Compiles typed declarations into deterministic, deduplicated CSS.
public enum TypedCSSCompiler {
  /// Compiles styles while preserving an input class name for each style.
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
