@_spi(Rendering) import RobinCore
import RobinHTML

extension RobinHTML.Component {
  func styled(
    _ property: StyleProperty,
    _ value: ModifierValue,
    on condition: Condition
  ) -> StyleDeclaration {
    StyleDeclaration(
      property: property.rawValue,
      payload: value.styleValue.payload,
      condition: condition.styleCondition.key
    )
  }
}

enum ModifierValue {
  case keyword(String)
  case color(String)
  case radius(String)
  case spacing(String)
  case fontFamily(String)
  case fontSize(String)
  case fontWeightToken(String)
  case pixels(Int)
  case number(Int)
  case shadow(String)

  var styleValue: StyleValue {
    switch self {
    case .keyword(let value): .keyword(value)
    case .color(let value): .color(value)
    case .radius(let value): .radius(value)
    case .spacing(let value): .spacing(value)
    case .fontFamily(let value): .fontFamily(value)
    case .fontSize(let value): .fontSize(value)
    case .fontWeightToken(let value): .fontWeightToken(value)
    case .pixels(let value): .pixels(value)
    case .number(let value): .number(value)
    case .shadow(let value): .shadow(value)
    }
  }
}

extension Condition {
  var styleCondition: StyleCondition {
    switch self {
    case .always: .always
    case .minimumWidth(let token): .minimumWidthToken(token.rawValue)
    case .hover: .hover
    case .focus: .focus
    case .dark: .dark
    case .containerMinimumWidth(let token): .containerMinimumWidthToken(token.rawValue)
    case .startingStyle: .startingStyle
    case .below, .between, .checked, .open, .has, .and, .or, .not:
      .expression(encoded)
    }
  }

  private var encoded: String {
    switch self {
    case .always: "always"
    case .minimumWidth(let token): "min:\(token.rawValue)"
    case .hover: "pseudo:hover"
    case .focus: "pseudo:focus"
    case .dark: "dark"
    case .below(let token): "max:\(token.rawValue)"
    case .between(let lower, let upper): "between:\(lower.rawValue):\(upper.rawValue)"
    case .checked: "pseudo:checked"
    case .open: "pseudo:open"
    case .has(let selector): "has:\(selector.utf8.count):\(selector)"
    case .and(let lhs, let rhs): "and:\(lhs.encoded.utf8.count):\(lhs.encoded)\(rhs.encoded)"
    case .or(let lhs, let rhs): "or:\(lhs.encoded.utf8.count):\(lhs.encoded)\(rhs.encoded)"
    case .not(let value): "not:\(value.encoded)"
    case .containerMinimumWidth(let token): "container-min:\(token.rawValue)"
    case .startingStyle: "starting-style"
    }
  }
}
