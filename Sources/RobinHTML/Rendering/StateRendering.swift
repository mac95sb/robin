import Foundation
@_spi(Rendering) import RobinRuntime

extension HTMLRenderer {
  /// Whether a tree uses browser-local bindings or actions.
  /// - Parameter root: The resolved component tree.
  /// - Returns: Whether the shared state runtime is needed.
  @_spi(Rendering) public static func requiresClientState(_ root: RenderNode) -> Bool {
    !stateIdentifiers(in: root).isEmpty
  }

  static func stateIdentifiers(in root: RenderNode) -> [String: String] {
    var identifiers: [String: String] = [:]
    func walk(_ node: RenderNode) {
      switch node.renderingStorage {
      case .text: break
      case .fragment(let children): children.forEach(walk)
      case .element(let element):
        for attribute in element.attributes {
          for reference in attribute.stateReferences where identifiers[reference.token] == nil {
            identifiers[reference.token] = "s\(identifiers.count)"
          }
        }
        element.children.forEach(walk)
      }
    }
    walk(root)
    return identifiers
  }

  static func stateAttributeValue(
    _ attribute: RenderElement.Attribute, identifiers: [String: String]
  ) throws -> String? {
    func descriptor(_ reference: StateReference) -> [String] {
      [identifiers[reference.token]!, reference.kind.rawValue, reference.initial]
    }
    func expression(_ node: StateExpressionNode) -> [Any] {
      switch node {
      case .literal(let json): ["literal", json]
      case .state(let reference): ["state", descriptor(reference)]
      case .add(let lhs, let rhs): ["add", expression(lhs), expression(rhs)]
      case .subtract(let lhs, let rhs): ["subtract", expression(lhs), expression(rhs)]
      case .not(let operand): ["not", expression(operand)]
      }
    }
    if let action = attribute.clientAction {
      let mutations: [[Any]] = action.mutations.map {
        [
          descriptor($0.reference), $0.operation.rawValue,
          $0.expression.map(expression) ?? NSNull(),
        ]
      }
      return String(
        decoding: try JSONSerialization.data(withJSONObject: mutations, options: [.sortedKeys]),
        as: UTF8.self)
    }
    guard let reference = attribute.stateReferences.first else { return nil }
    return String(decoding: try JSONEncoder().encode(descriptor(reference)), as: UTF8.self)
  }
}

extension RenderElement.Attribute {
  var clientAction: StateAction? {
    switch self {
    case .stateAction(let action), .stateOnChange(let action), .stateOnInput(let action): action
    default: nil
    }
  }

  var stateReferences: [StateReference] {
    func references(_ expression: StateExpressionNode) -> [StateReference] {
      switch expression {
      case .literal: []
      case .state(let reference): [reference]
      case .add(let lhs, let rhs), .subtract(let lhs, let rhs): references(lhs) + references(rhs)
      case .not(let operand): references(operand)
      }
    }
    if let action = clientAction {
      return action.mutations.flatMap { [$0.reference] + ($0.expression.map(references) ?? []) }
    }
    return switch self {
    case .stateText(let reference), .stateInput(let reference), .stateHidden(let reference),
      .stateVisible(let reference), .stateDisabled(let reference):
      [reference]
    default: []
    }
  }
}
