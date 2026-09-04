import ArgumentParser

/// A plugin that contributes Robin command-line subcommands.
public protocol CommandPlugin: Plugin {
  /// Commands registered beneath the `robin` executable.
  var commands: [any ParsableCommand.Type] { get }
}
