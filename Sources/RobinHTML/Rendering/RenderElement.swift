import RobinCore

/// An element in Robin's structural render representation.
///
/// Render elements contain only typed structural data. Style declarations are carried as opaque
/// `StyleDeclaration` values: their shape is defined by `RobinCore`, while their interpretation
/// and compilation into CSS belong entirely to `RobinStyle`. Renderer implementations translate
/// this representation into their output format.
public struct RenderElement: Equatable, Sendable {
  /// The closed set of element kinds emitted by the current component vocabulary.
  public enum Kind: String, Equatable, Sendable {
    /// A hyperlink.
    case a
    /// An article landmark.
    case article
    /// A tangential aside landmark.
    case aside
    /// A quoted block of content.
    case blockquote
    /// An interactive button.
    case button
    /// An inline or preformatted code fragment.
    case code
    /// A disclosure widget.
    case details
    /// A modal or non-modal dialog.
    case dialog
    /// A neutral block-level container used by structural layout components.
    case div
    /// Emphasized inline text.
    case em
    /// Self-contained content with an optional caption.
    case figure
    /// The caption for a ``figure`` element.
    case figcaption
    /// A form for collecting and submitting user input.
    case form
    /// A footer landmark.
    case footer
    /// A level-one heading.
    case h1
    /// A level-two heading.
    case h2
    /// A level-three heading.
    case h3
    /// A level-four heading.
    case h4
    /// A level-five heading.
    case h5
    /// A level-six heading.
    case h6
    /// A header landmark.
    case header
    /// An image.
    case img
    /// A sandboxed third-party embedded document.
    case iframe
    /// A form input control.
    case input
    /// A caption for a form control.
    case label
    /// A list item.
    case li
    /// The document's main landmark.
    case main
    /// A navigation landmark.
    case nav
    /// An ordered list.
    case ol
    /// A paragraph.
    case p
    /// A preformatted text block.
    case pre
    /// A search landmark.
    case search
    /// A thematic section.
    case section
    /// An inline text container.
    case span
    /// The disclosure summary label for a ``details`` element.
    case summary
    /// Strongly emphasized inline text.
    case strong
    /// A table.
    case table
    /// A table data cell.
    case td
    /// A multiline text input control.
    case textarea
    /// A table header cell.
    case th
    /// A table row.
    case tr
    /// An unordered list.
    case ul

    /// Whether the element never has children and serializes without a closing tag.
    var isVoid: Bool {
      switch self {
      case .img, .input: true
      default: false
      }
    }
  }

  /// The closed set of structural attributes understood by the renderer.
  public enum Attribute: Equatable, Sendable {
    /// A stable element identifier.
    case identifier(String)
    /// The behavior of a button element.
    case buttonType(ButtonType)
    /// The behavior of an input element.
    case inputType(InputType)
    /// The form control's submission name.
    case name(String)
    /// The form control's value.
    case value(String)
    /// An accessible label for the element.
    case accessibilityLabel(String)
    /// A hyperlink's destination, serialized as `href`.
    case href(String)
    /// A media element's source, serialized as `src`.
    case source(String)
    /// An image's alternative text, serialized as `alt`.
    case alternateText(String)
    /// A form's submission endpoint, serialized as `action`.
    case action(String)
    /// A form's submission method.
    case formMethod(FormMethod)
    /// A label's associated control identifier, serialized as `for`.
    case labelFor(String)
    /// A disclosure or dialog's expanded/visible state, serialized as the bare `open` attribute.
    case open
    /// An embedded document's human-readable title.
    case title(String)
    /// The fixed sandbox capability set for an embedded document.
    case sandbox(String)
    /// The source language associated with a syntax-highlighted code block.
    case syntaxLanguage(String)
    /// The curated syntax theme selected for a code block.
    case syntaxTheme(SyntaxHighlightTheme)
    /// The semantic role of a highlighted source-code region.
    case syntaxHighlight(CaseHighlight.Kind)

    /// A typed HTML form submission method.
    public enum FormMethod: String, Equatable, Sendable {
      /// Submits the form as a URL query string via `GET`.
      case get
      /// Submits the form as a request body via `POST`.
      case post
    }

    /// A typed HTML button behavior.
    public enum ButtonType: String, Equatable, Sendable {
      /// A button with no default form-submission behavior.
      case button
      /// A button that submits its associated form.
      case submit
      /// A button that resets its associated form.
      case reset
    }

    /// A typed HTML input behavior.
    public enum InputType: String, Equatable, Sendable {
      /// A plain text input.
      case text
      /// An email address input.
      case email
      /// A password input whose value is obscured.
      case password
      /// A search query input.
      case search
      /// A numeric input.
      case number
      /// A URL input.
      case url
      /// A telephone number input, serialized as the HTML `tel` type.
      case telephone = "tel"
    }
  }

  /// The semantic element kind.
  public let kind: Kind
  /// Structural attributes supplied by the component initializer.
  public let attributes: [Attribute]
  /// Normalized style declarations attached during component lowering.
  ///
  /// Declarations are opaque to the render layer: `RobinCore` defines only the declaration
  /// *shape*, while `RobinStyle` owns token resolution, cascade ordering, and CSS emission.
  public let styles: [StyleDeclaration]
  /// Child nodes in source order.
  public let children: [RenderNode]

  /// Creates an element in the structural render representation.
  ///
  /// - Parameters:
  ///   - kind: The semantic kind of element.
  ///   - attributes: Structural attributes supplied by the component initializer.
  ///   - styles: Opaque style declarations attached to the element.
  ///   - children: Child nodes in source order.
  @_spi(Rendering)
  public init(
    kind: Kind,
    attributes: [Attribute] = [],
    styles: [StyleDeclaration] = [],
    children: [RenderNode] = []
  ) {
    self.kind = kind
    self.attributes = attributes
    self.styles = styles
    self.children = children
  }
}
