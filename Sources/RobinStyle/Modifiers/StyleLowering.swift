@_spi(Rendering) import RobinCore
import RobinHTML

extension RobinHTML.Component {
  func styled(
    _ property: StyleProperty,
    _ value: StyleValue,
    on condition: Condition
  ) -> StyleDeclaration {
    StyleDeclaration(
      property: property.rawValue,
      payload: value.payload,
      condition: condition.styleCondition.key
    )
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
