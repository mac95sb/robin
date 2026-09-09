import RobinCore
@_spi(Rendering) import RobinRuntime

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
    /// A circle in an inline vector image.
    case circle
    /// An inline or preformatted code fragment.
    case code
    /// A disclosure widget.
    case details
    /// A modal or non-modal dialog.
    case dialog
    /// A neutral block-level container used by structural layout components.
    case div
    /// An ellipse in an inline vector image.
    case ellipse
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
    /// A line in an inline vector image.
    case line
    /// A list item.
    case li
    /// The document's main landmark.
    case main
    /// A navigation landmark.
    case nav
    /// An ordered list.
    case ol
    /// A native dropdown control.
    case select
    /// A choice in a native dropdown.
    case option
    /// A paragraph.
    case p
    /// A path in an inline vector image.
    case path
    /// A polygon in an inline vector image.
    case polygon
    /// A polyline in an inline vector image.
    case polyline
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
    /// Superscript phrasing content.
    case sup
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
    /// An inline vector image.
    case svg
    /// A rectangle in an inline vector image.
    case rect

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
    /// Enables a native auto popover.
    case popover
    /// A standard popover command and target.
    case popoverCommand(PopoverCommand)
    /// A generated popover invoker scoped by the renderer.
    case popoverTrigger(String)
    /// Generated native popover content scoped by the renderer.
    case popoverContent(String)
    /// A generated command that dismisses its enclosing popover.
    case popoverDismiss(String)
    /// A locale destination preserving the current page route.
    case languageLink(String)
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
    /// Marks the initially selected dropdown option.
    case selected
    /// Selects a persistent appearance preference from a button.
    case appearanceChoice(AppearanceButton.Preference)
    /// Whether a toggle button is currently selected.
    case accessibilityPressed(Bool)
    /// Binds a native dropdown to appearance preferences.
    case appearancePicker
    /// Applies a persisted appearance preference from local state.
    case appearanceState(StateReference)
    /// Binds a native dropdown to localized navigation.
    case languagePicker
    /// Requires a value before native form submission.
    case required
    /// The minimum text length, measured in UTF-16 code units.
    case minimumLength(Int)
    /// The maximum text length, measured in UTF-16 code units.
    case maximumLength(Int)
    /// Identifies elements describing this control.
    case accessibilityDescribedBy(String)
    /// Marks a control whose submitted value failed validation.
    case accessibilityInvalid
    /// An accessible label for the element.
    case accessibilityLabel(String)
    /// A hyperlink's destination, serialized as `href`.
    case href(String)
    /// A media element's source, serialized as `src`.
    case source(String)
    /// Responsive image candidates, serialized as `srcset`.
    case sourceSet([SourceCandidate])
    /// The responsive image slot-size expression, serialized as `sizes`.
    case sizes(String)
    /// An image's alternative text, serialized as `alt`.
    case alternateText(String)
    /// A form's submission endpoint, serialized as `action`.
    case action(String)
    /// A form's submission method.
    case formMethod(FormMethod)
    /// Uses multipart encoding to submit file controls.
    case multipartEncoding
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
    /// Hides the number input’s native stepper while retaining numeric behavior.
    case hiddenNumberStepper
    /// Reactive text content.
    case stateText(StateReference)
    /// Two-way input value or checked binding.
    case stateInput(StateReference)
    /// Reactive visibility.
    case stateHidden(StateReference)
    /// Reactive native disabled state.
    case stateDisabled(StateReference)
    /// A typed browser-local mutation.
    case stateAction(StateAction)
    /// An action following a committed native input change.
    case stateOnChange(StateAction)
    /// An action following each native input edit.
    case stateOnInput(StateAction)
    /// A native tab group whose generated controls are scoped by the renderer.
    case tabs(String)
    /// A generated native tab control.
    case tabControl(String, Int)
    /// A generated label for a native tab control.
    case tabLabel(String, Int)
    /// A panel controlled by a native tab control.
    case tabPanel
    /// Reactive visibility when the state is true.
    case stateVisible(StateReference)
    /// Initially hidden content.
    case hidden
    /// Initially disabled native control.
    case disabled
    /// Initially checked native checkbox.
    case checked
    /// Allows fractional numeric input.
    case anyStep

    /// The semantic role of a highlighted source-code region.
    case syntaxHighlight(CaseHighlight.Kind)
    /// Hides decorative content from assistive technologies.
    case accessibilityHidden
    /// Marks an inline vector as an image for assistive technologies.
    case imageRole
    /// Preserves native list semantics when visible markers are removed.
    case listRole
    /// A vector element's horizontal origin.
    case vectorX(String)
    /// A vector element's vertical origin.
    case vectorY(String)
    /// A vector element's width.
    case vectorWidth(String)
    /// A vector element's height.
    case vectorHeight(String)
    /// A vector element's horizontal center.
    case vectorCenterX(String)
    /// A vector element's vertical center.
    case vectorCenterY(String)
    /// A vector element's radius.
    case vectorRadius(String)
    /// A vector element's horizontal radius.
    case vectorRadiusX(String)
    /// A vector element's vertical radius.
    case vectorRadiusY(String)
    /// A vector line's first horizontal coordinate.
    case vectorX1(String)
    /// A vector line's first vertical coordinate.
    case vectorY1(String)
    /// A vector line's second horizontal coordinate.
    case vectorX2(String)
    /// A vector line's second vertical coordinate.
    case vectorY2(String)
    /// A vector path's command data.
    case vectorPath(String)
    /// A vector polygon or polyline's points.
    case vectorPoints(String)
    /// A vector image's coordinate system.
    case vectorViewBox(String)
    /// A vector element's fill paint.
    case vectorFill(String)
    /// A vector element's stroke paint.
    case vectorStroke(String)
    /// A vector element's stroke width.
    case vectorStrokeWidth(String)
    /// A vector element's stroke line-cap shape.
    case vectorStrokeLineCap(String)
    /// A vector element's stroke line-join shape.
    case vectorStrokeLineJoin(String)

    /// One image source and its intrinsic pixel width.
    public struct SourceCandidate: Equatable, Sendable {
      /// The image source reference.
      public let source: String
      /// The source width in pixels.
      public let width: Int

      /// Creates a responsive image candidate.
      ///
      /// - Parameters:
      ///   - source: The image source reference.
      ///   - width: The positive intrinsic width in pixels.
      public init(source: String, width: Int) {
        self.source = source
        self.width = width
      }
    }

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
      /// A Boolean checkbox.
      case checkbox
      /// An exclusive native choice within a named group.
      case radio
      /// A URL input.
      case url
      /// A telephone number input, serialized as the HTML `tel` type.
      case telephone = "tel"
      /// An uploaded file selected by the user.
      case file
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
