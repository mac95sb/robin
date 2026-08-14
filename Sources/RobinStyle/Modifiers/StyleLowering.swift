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
    }
  }
}
