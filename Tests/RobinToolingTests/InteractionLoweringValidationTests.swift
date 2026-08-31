import Testing

@testable import RobinTooling

@Suite("Interaction lowering validation")
struct InteractionLoweringValidationTests {
  @Test func acceptsNativeThenCommandThenModuleHierarchy() {
    let observations = [
      InteractionObservation(
        name: "Open dialog",
        nativeBehaviorAvailable: true,
        targetOwnedCommand: true,
        lowering: .native
      ),
      InteractionObservation(
        name: "Archive row",
        nativeBehaviorAvailable: false,
        targetOwnedCommand: true,
        lowering: .customCommand(target: "row-42")
      ),
      InteractionObservation(
        name: "Subscribe to updates",
        nativeBehaviorAvailable: false,
        targetOwnedCommand: false,
        lowering: .directModule(.liveUpdates)
      ),
    ]

    #expect(InteractionLoweringValidation.validate(observations).isEmpty)
  }

  @Test func diagnosesRawAndMisorderedLowering() {
    let observations = [
      InteractionObservation(
        name: "Open popover",
        nativeBehaviorAvailable: true,
        targetOwnedCommand: true,
        lowering: .directModule(.customCommand),
        usesRawCommandString: true,
        usesRawEventHandler: true
      )
    ]

    #expect(
      InteractionLoweringValidation.validate(observations) == [
        .runtimeUsedWhereNativeSuffices(interaction: "Open popover"),
        .rawCommandString(interaction: "Open popover"),
        .rawEventHandler(interaction: "Open popover"),
        .directModuleUsedForTargetOwnedCommand(interaction: "Open popover"),
      ]
    )
  }
}
