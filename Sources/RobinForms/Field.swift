import Foundation
@_spi(Rendering) import RobinHTML

/// Associates a stable form-field name with a codable value.
@propertyWrapper
public struct Field<Value: Codable & Sendable>: Sendable {
  /// The stable transport-facing field name.
  public let name: String
  /// The field's current typed value.
  public var wrappedValue: Value
  /// The visible and accessible label for the native control.
  public let label: String
  /// Whether an empty or missing submission is invalid.
  public let required: Bool
  /// The shared native and server minimum text length in UTF-16 code units.
  public let minimumLength: Int?
  /// The shared native and server maximum text length in UTF-16 code units.
  public let maximumLength: Int?
  /// The most recent decoding or validation error, if any.
  public private(set) var validationError: FieldValidationError?
  private let validation: @Sendable (Value) -> String?
  private var submittedText: String?

  /// Creates a named form field.
  ///
  /// - Parameters:
  ///   - wrappedValue: The field's initial value.
  ///   - name: The stable transport-facing name.
  ///   - label: The visible control label; defaults to the field name.
  ///   - required: Whether an empty or missing value is rejected.
  ///   - minimumLength: An optional minimum UTF-16 text length.
  ///   - maximumLength: An optional maximum UTF-16 text length.
  ///   - validate: Additional server validation; return a user-facing error or `nil`.
  public init(
    wrappedValue: Value, _ name: String, label: String? = nil, required: Bool = false,
    minimumLength: Int? = nil, maximumLength: Int? = nil,
    validate: @escaping @Sendable (Value) -> String? = { _ in nil }
  ) {
    precondition(!name.isEmpty && !name.contains(where: { $0.isWhitespace }))
    precondition(minimumLength.map { $0 >= 0 } ?? true)
    precondition(maximumLength.map { $0 >= (minimumLength ?? 0) } ?? true)
    self.name = name
    self.wrappedValue = wrappedValue
    self.label = label ?? name
    self.required = required
    self.minimumLength = minimumLength
    self.maximumLength = maximumLength
    self.validation = validate
  }

  /// The field metadata and value exposed through `$field`.
  public var projectedValue: Field<Value> { self }

  /// Applies a transport value and validates it without discarding invalid text needed for redisplay.
  public mutating func decode(from values: FormValues) {
    validationError = nil
    submittedText = nil
    guard let submitted = values.fields[name] else {
      if required { validationError = .missing(name) }
      return
    }
    do {
      let decoded: Value
      switch submitted {
      case .text(let text):
        submittedText = text
        decoded = try (text as? Value) ?? JSONDecoder().decode(Value.self, from: Data(text.utf8))
      case .json(let data):
        if required && data == Data("null".utf8) { throw FieldValidationError.missing(name) }
        submittedText =
          (try? JSONDecoder().decode(String.self, from: data))
          ?? String(data: data, encoding: .utf8)
        decoded = try JSONDecoder().decode(Value.self, from: data)
      case .file(let file):
        guard let value = file as? Value else {
          throw FieldValidationError.invalid(name, reason: "Select a valid file.")
        }
        decoded = value
      }
      if required, let file = decoded as? FileField, file.filename.isEmpty {
        throw FieldValidationError.missing(name)
      }
      if let text = submittedText {
        if required && text.isEmpty { throw FieldValidationError.missing(name) }
        if let minimumLength, !text.isEmpty, text.utf16.count < minimumLength {
          throw FieldValidationError.invalid(
            name, reason: "Enter at least \(minimumLength) characters.")
        }
        if let maximumLength, text.utf16.count > maximumLength {
          throw FieldValidationError.invalid(
            name, reason: "Enter at most \(maximumLength) characters.")
        }
      }
      if let reason = validation(decoded) {
        throw FieldValidationError.invalid(name, reason: reason)
      }
      wrappedValue = decoded
    } catch let error as FieldValidationError {
      validationError = error
    } catch {
      validationError = .invalid(name, reason: "Enter a valid value.")
    }
  }
}

extension Field: Component {
  /// A labeled native control followed by its associated inline validation error.
  public var body: ComponentContent {
    input(id: name)
  }

  /// Renders the field with an explicit document identifier when multiple forms share field names.
  @ViewBuilder public func input(id: String) -> ComponentContent {
    Label(for: id) { label }
    control(id: id)
    if let validationError { Text(id: "\(id)-error") { validationError.message } }
  }

  private func control(id: String) -> ComponentContent {
    let isFile = Value.self == FileField.self
    var attributes: [RenderElement.Attribute] = [
      .identifier(id), .name(name), .inputType(isFile ? .file : .text),
      .accessibilityLabel(label),
    ]
    if !isFile {
      let initial =
        (wrappedValue as? String)
        ?? (try? JSONEncoder().encode(wrappedValue)).flatMap { String(data: $0, encoding: .utf8) }
      attributes.append(.value(submittedText ?? initial ?? ""))
    }
    if required { attributes.append(.required) }
    if let minimumLength { attributes.append(.minimumLength(minimumLength)) }
    if let maximumLength { attributes.append(.maximumLength(maximumLength)) }
    if validationError != nil {
      attributes += [.accessibilityInvalid, .accessibilityDescribedBy("\(id)-error")]
    }
    return .node(.element(.init(kind: .input, attributes: attributes)))
  }
}
