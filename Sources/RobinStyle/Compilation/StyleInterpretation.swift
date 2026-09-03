@_spi(Rendering) import RobinCore

enum StyleProperty: String, Hashable {
  case anchorName = "anchor-name"
  case alignItems = "align-items"
  case animationDuration = "animation-duration"
  case animationName = "animation-name"
  case animationTimeline = "animation-timeline"
  case backgroundColor = "background-color"
  case borderColor = "border-color"
  case borderRadius = "border-radius"
  case borderStyle = "border-style"
  case borderWidth = "border-width"
  case color
  case containerType = "container-type"
  case contentVisibility = "content-visibility"
  case display
  case flexDirection = "flex-direction"
  case flexWrap = "flex-wrap"
  case flexGrow = "flex-grow"
  case flexShrink = "flex-shrink"
  case flexBasis = "flex-basis"
  case fontFamily = "font-family"
  case fontSize = "font-size"
  case fontWeight = "font-weight"
  case gap
  case gridAutoFlow = "grid-auto-flow"
  case gridColumn = "grid-column"
  case gridRow = "grid-row"
  case gridTemplateColumns = "grid-template-columns"
  case gridTemplateRows = "grid-template-rows"
  case justifyContent = "justify-content"
  case padding
  case positionAnchor = "position-anchor"
  case scrollTimelineName = "scroll-timeline-name"
  case top
  case transitionBehavior = "transition-behavior"
  case viewTimelineName = "view-timeline-name"
  case boxShadow = "box-shadow"
  case margin
  case width
  case minWidth = "min-width"
  case maxWidth = "max-width"
  case height
  case minHeight = "min-height"
  case maxHeight = "max-height"
  case aspectRatio = "aspect-ratio"
  case order
  case textAlign = "text-align"
}

enum StyleValue: Equatable {
  case keyword(String)
  case color(String)
  case spacing(String)
  case radius(String)
  case fontFamily(String)
  case fontSize(String)
  case fontWeight(Int)
  case fontWeightToken(String)
  case pixels(Int)
  case number(Int)
  case shadow(String)

  init(payload: StyleDeclaration.Payload, property: StyleProperty) {
    switch payload {
    case .keyword(let value):
      self = .keyword(value)
    case .integer(let value):
      switch property {
      case .fontWeight: self = .fontWeight(value)
      case .order, .flexGrow, .flexShrink, .gridColumn, .gridRow: self = .number(value)
      default: self = .pixels(value)
      }
    case .token(let name):
      switch property {
      case .backgroundColor, .borderColor, .color:
        self = .color(name)
      case .borderRadius:
        self = .radius(name)
      case .boxShadow:
        self = .shadow(name)
      case .fontFamily:
        self = .fontFamily(name)
      case .fontSize:
        self = .fontSize(name)
      case .fontWeight:
        self = .fontWeightToken(name)
      case .gap, .padding:
        self = .spacing(name)
      default:
        preconditionFailure("Unsupported token-backed style property: \(property.rawValue)")
      }
    }
  }

  var payload: StyleDeclaration.Payload {
    switch self {
    case .keyword(let value): .keyword(value)
    case .color(let name), .spacing(let name), .radius(let name), .fontFamily(let name),
      .fontSize(let name), .fontWeightToken(let name), .shadow(let name):
      .token(name)
    case .fontWeight(let value), .pixels(let value), .number(let value): .integer(value)
    }
  }
}

enum StyleCondition: Hashable {
  case always
  case minimumWidth(Int)
  case minimumWidthToken(String)
  case hover
  case focus
  case dark
  case expression(String)
  case containerMinimumWidthToken(String)
  case startingStyle

  init(key: String) {
    switch key {
    case "": self = .always
    case "hover": self = .hover
    case "focus": self = .focus
    case "dark": self = .dark
    case "starting-style": self = .startingStyle
    default:
      if let value = key.removingPrefix("minimum-width-token:") {
        self = .minimumWidthToken(value)
      } else if let value = key.removingPrefix("container-minimum-width-token:") {
        self = .containerMinimumWidthToken(value)
      } else if let value = key.removingPrefix("minimum-width:"), let width = Int(value) {
        self = .minimumWidth(width)
      } else if let value = key.removingPrefix("expression:") {
        self = .expression(value)
      } else {
        preconditionFailure("Unsupported style condition key: \(key)")
      }
    }
  }

  var key: String {
    switch self {
    case .always: ""
    case .minimumWidth(let width): "minimum-width:\(width)"
    case .minimumWidthToken(let name): "minimum-width-token:\(name)"
    case .hover: "hover"
    case .focus: "focus"
    case .dark: "dark"
    case .expression(let value): "expression:\(value)"
    case .containerMinimumWidthToken(let name): "container-minimum-width-token:\(name)"
    case .startingStyle: "starting-style"
    }
  }

  var layer: StyleLayer {
    switch self {
    case .always: .base
    case .minimumWidth, .minimumWidthToken, .containerMinimumWidthToken: .responsive
    case .hover, .focus: .state
    case .dark: .mode
    case .expression, .startingStyle: .state
    }
  }

  var sortKey: String {
    switch self {
    case .always: "0"
    case .minimumWidth(let width): "1:width:\(width)"
    case .minimumWidthToken(let name): "1:token:\(name)"
    case .focus: "2:focus"
    case .hover: "2:hover"
    case .dark: "3:dark"
    case .expression(let value): "2:expression:\(value)"
    case .containerMinimumWidthToken(let name): "1:container:\(name)"
    case .startingStyle: "2:starting-style"
    }
  }
}

enum StyleLayer: Int {
  case base
  case responsive
  case state
  case mode
}

struct InterpretedStyle {
  let source: StyleDeclaration
  let property: StyleProperty
  let value: StyleValue
  let condition: StyleCondition

  init(_ source: StyleDeclaration) {
    guard let property = StyleProperty(rawValue: source.property) else {
      preconditionFailure("Unsupported style property key: \(source.property)")
    }
    self.source = source
    self.property = property
    self.value = StyleValue(payload: source.payload, property: property)
    self.condition = StyleCondition(key: source.condition)
  }
}

extension String {
  fileprivate func removingPrefix(_ prefix: String) -> String? {
    guard hasPrefix(prefix) else { return nil }
    return String(dropFirst(prefix.count))
  }
}
