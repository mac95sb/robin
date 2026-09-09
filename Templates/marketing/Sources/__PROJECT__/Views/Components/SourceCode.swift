import RobinHTML
import RobinStyle

/// A styled, syntax-highlighted source listing.
struct SourceCode: Component {
  private let source: String
  private let language: String

  /// Creates a source listing for a programming language.
  init(_ source: String, language: String) {
    self.source = source
    self.language = language
  }

  var body: ComponentContent {
    CodeBlock(source, language: language, theme: .xcode)
      .margin(.zero).padding(.lg).border(color: .border, width: 0, radius: .lg).frame(minWidth: 0)
  }
}
