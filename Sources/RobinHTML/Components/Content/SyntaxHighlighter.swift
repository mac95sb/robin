/// Native, theme-independent syntax highlighting for code rendered by Robin.
public struct SyntaxHighlighter {
  private init() {}
  /// One contiguous semantic region. `kind == nil` means ordinary source text.
  public struct Run: Equatable, Sendable {
    /// The semantic role, or `nil` for unhighlighted source.
    public let kind: CaseHighlight.Kind?
    /// The source text in this region.
    public let text: String

    /// Creates a highlighted or plain source run.
    public init(kind: CaseHighlight.Kind?, text: String) {
      self.kind = kind
      self.text = text
    }
  }

  /// Highlights source into merged semantic regions without wrapping every lexical token.
  public static func highlight(_ source: String, language: String? = nil) -> [Run] {
    var runs: [Run] = []
    var index = source.startIndex
    let hashComments = ["bash", "python", "ruby", "shell", "sh", "yaml", "yml"].contains(
      language?.lowercased() ?? "")

    while index < source.endIndex {
      let start = index
      let character = source[index]

      if source[index...].hasPrefix("//") || source[index...].hasPrefix("/*") {
        let block = source[index...].hasPrefix("/*")
        index = source.index(index, offsetBy: 2)
        if block, let end = source[index...].range(of: "*/")?.upperBound {
          index = end
        } else if !block, let end = source[index...].firstIndex(of: "\n") {
          index = end
        } else {
          index = source.endIndex
        }
        append(.comment, String(source[start..<index]), to: &runs)
      } else if hashComments && character == "#" {
        index = source[index...].firstIndex(of: "\n") ?? source.endIndex
        append(.comment, String(source[start..<index]), to: &runs)
      } else if character == "\"" || character == "'" || character == "`" {
        let quote = character
        index = source.index(after: index)
        var escaped = false
        while index < source.endIndex {
          let next = source[index]
          index = source.index(after: index)
          if next == quote && !escaped { break }
          escaped = next == "\\" && !escaped
          if next != "\\" { escaped = false }
        }
        append(.string, String(source[start..<index]), to: &runs)
      } else if character.isNumber {
        index = source.index(after: index)
        while index < source.endIndex,
          source[index].isNumber || ".xobABCDEFabcdef_".contains(source[index])
        {
          index = source.index(after: index)
        }
        append(.number, String(source[start..<index]), to: &runs)
      } else if character.isLetter || character == "_" {
        index = source.index(after: index)
        while index < source.endIndex,
          source[index].isLetter || source[index].isNumber || source[index] == "_"
        {
          index = source.index(after: index)
        }
        let word = String(source[start..<index])
        let kind: CaseHighlight.Kind?
        if literals.contains(word) {
          kind = .literal
        } else if keywords.contains(word) {
          kind = .keyword
        } else if word.first?.isUppercase == true {
          kind = .type
        } else if source[index...].drop(while: { $0.isWhitespace }).first == "(" {
          kind = .function
        } else {
          kind = nil
        }
        append(kind, word, to: &runs)
      } else {
        index = source.index(after: index)
        append(nil, String(character), to: &runs)
      }
    }
    return runs
  }

  private static let literals: Set<String> = ["false", "nil", "null", "true"]
  private static let keywords: Set<String> = [
    "as", "async", "await", "break", "case", "catch", "class", "const", "continue",
    "default", "defer", "do", "else", "enum", "export", "extends", "final", "for", "from",
    "func", "function", "guard", "if", "import", "in", "interface", "let", "mutating", "new",
    "private", "protocol", "public", "repeat", "return", "static", "struct", "switch", "throw",
    "throws", "try", "typealias", "var", "while", "yield",
  ]

  private static func append(_ kind: CaseHighlight.Kind?, _ text: String, to runs: inout [Run]) {
    guard !text.isEmpty else { return }
    if let last = runs.last, last.kind == kind {
      runs[runs.index(before: runs.endIndex)] = Run(kind: kind, text: last.text + text)
    } else {
      runs.append(Run(kind: kind, text: text))
    }
  }
}
