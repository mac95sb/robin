import RobinCore

/// An element in Robin's structural render representation.
///
/// Render elements contain only typed structural data. Style declarations are carried as opaque
/// ``StyleDeclaration`` values: their shape is defined by `RobinCore`, while their interpretation
/// and compilation into CSS belong entirely to `RobinStyle`. Renderer implementations translate
/// this representation into their output format.
public struct RenderElement: Equatable, Sendable {
  /// The closed set of element kinds emitted by the current component vocabulary.
  public enum Kind: String, Equatable, Sendable {
    /// An article landmark.
    case article
    /// An interactive button.
    case button
    /// A neutral block-level container used by structural layout components.
    case div
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
    /// A form input control.
    case input
    /// The document's main landmark.
    case main
    /// A navigation landmark.
    case nav
    /// A paragraph.
    case p
    /// A thematic section.
    case section
    /// An inline text container.
    case span
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
