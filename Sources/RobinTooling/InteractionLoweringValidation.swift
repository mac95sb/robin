import Foundation

/// The generated representation chosen for an application interaction.
public enum InteractionLowering: Equatable, Sendable {
  case native
  case customCommand(target: String)
  case directModule(RuntimeCapability)
}

/// One interaction observed while validating generated output.
public struct InteractionObservation: Equatable, Sendable {
  public let name: String
  public let nativeBehaviorAvailable: Bool
  public let targetOwnedCommand: Bool
  public let lowering: InteractionLowering
  public let usesRawCommandString: Bool
  public let usesRawEventHandler: Bool

  public init(
    name: String,
    nativeBehaviorAvailable: Bool,
    targetOwnedCommand: Bool,
    lowering: InteractionLowering,
    usesRawCommandString: Bool = false,
    usesRawEventHandler: Bool = false
  ) {
    self.name = name
    self.nativeBehaviorAvailable = nativeBehaviorAvailable
    self.targetOwnedCommand = targetOwnedCommand
    self.lowering = lowering
    self.usesRawCommandString = usesRawCommandString
    self.usesRawEventHandler = usesRawEventHandler
  }
}

/// Validates Robin's native-first interaction-lowering hierarchy.
public enum InteractionLoweringValidation {
  public enum Violation: Equatable, Sendable {
    case runtimeUsedWhereNativeSuffices(interaction: String)
    case rawCommandString(interaction: String)
    case rawEventHandler(interaction: String)
    case commandWithoutMeaningfulTarget(interaction: String)
    case directModuleUsedForTargetOwnedCommand(interaction: String)
  }

  public static func validate(_ observations: [InteractionObservation]) -> [Violation] {
    observations.flatMap { observation in
      var violations: [Violation] = []
      if observation.nativeBehaviorAvailable, observation.lowering != .native {
        violations.append(.runtimeUsedWhereNativeSuffices(interaction: observation.name))
      }
      if observation.usesRawCommandString {
        violations.append(.rawCommandString(interaction: observation.name))
      }
      if observation.usesRawEventHandler {
        violations.append(.rawEventHandler(interaction: observation.name))
      }
      switch observation.lowering {
      case .native:
        break
      case .customCommand(let target):
        if !observation.targetOwnedCommand
          || target.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        {
          violations.append(.commandWithoutMeaningfulTarget(interaction: observation.name))
        }
      case .directModule:
        if observation.targetOwnedCommand {
          violations.append(.directModuleUsedForTargetOwnedCommand(interaction: observation.name))
        }
      }
      return violations
    }
  }
}
