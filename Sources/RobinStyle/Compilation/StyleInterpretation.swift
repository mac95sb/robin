@_spi(Rendering) import RobinCore

enum StyleProperty: String, Hashable {
  case alignItems = "align-items"
  case backgroundColor = "background-color"
  case borderColor = "border-color"
  case borderRadius = "border-radius"
  case borderStyle = "border-style"
  case borderWidth = "border-width"
  case color
  case contentVisibility = "content-visibility"
  case display
  case flexDirection = "flex-direction"
  case fontFamily = "font-family"
  case fontSize = "font-size"
  case fontWeight = "font-weight"
  case gap
  case justifyContent = "justify-content"
  case padding
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

  init(payload: StyleDeclaration.Payload, property: StyleProperty) {
    switch payload {
    case .keyword(let value):
      self = .keyword(value)
    case .integer(let value):
      self = property == .fontWeight ? .fontWeight(value) : .pixels(value)
    case .token(let name):
      switch property {
      case .backgroundColor, .borderColor, .color:
        self = .color(name)
      case .borderRadius:
        self = .radius(name)
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
      .fontSize(let name), .fontWeightToken(let name):
      .token(name)
    case .fontWeight(let value), .pixels(let value): .integer(value)
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

  init(key: String) {
    switch key {
    case "": self = .always
    case "hover": self = .hover
    case "focus": self = .focus
    case "dark": self = .dark
    default:
      if let value = key.removingPrefix("minimum-width-token:") {
        self = .minimumWidthToken(value)
      } else if let value = key.removingPrefix("minimum-width:"), let width = Int(value) {
        self = .minimumWidth(width)
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
    }
  }

  var layer: StyleLayer {
    switch self {
    case .always: .base
    case .minimumWidth, .minimumWidthToken: .responsive
    case .hover, .focus: .state
    case .dark: .mode
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
