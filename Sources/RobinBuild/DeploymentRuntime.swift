/// A provider-neutral runtime attached to one deployable artifact.
public struct DeploymentRuntime: Encodable, Sendable {
  /// The invocation contract implemented by the artifact.
  public enum Interface: String, Encodable, Sendable {
    /// A long-running HTTP listener.
    case persistentHTTP
    /// A native executable driven by a Lambda-style invocation API.
    case lambda
    /// A WebAssembly component implementing `wasi:http`.
    case wasiHTTP
    /// A WebAssembly core module used through a generated host adapter.
    case webAssembly
  }

  /// The instruction-set architecture of a runtime artifact.
  public enum Architecture: String, Encodable, Sendable {
    /// 64-bit Arm Linux.
    case arm64
    /// 64-bit x86 Linux.
    case x64 = "x86_64"
    /// WebAssembly with 32-bit linear-memory addresses.
    case wasm32
  }

  /// The invocation contract implemented by the artifact.
  public let interface: Interface
  /// The runtime artifact path before provider layout is applied.
  public let artifact: String
  /// The artifact's instruction-set architecture.
  public let architecture: Architecture
  /// The provider-visible bootstrap, handler, or exported function name.
  public let entryPoint: String?
  /// Generated glue that connects the artifact to its deployment host.
  public let hostAdapter: String?
  /// Environment-variable names the runtime is allowed to read.
  public let environment: [String]
  /// The compiler or SDK requirement used to produce the artifact.
  public let toolchain: String?
  /// The build or execution container image, when required by the provider.
  public let containerImage: String?
  /// The invocation limit in milliseconds, when one is configured.
  public let maximumDurationMilliseconds: Int?
  /// The memory limit in mebibytes, when one is configured.
  public let maximumMemoryMebibytes: Int?
  /// The artifact-size limit in bytes, when one is configured.
  public let maximumArtifactBytes: Int?

  /// Creates a provider-neutral deployment runtime.
  ///
  /// - Parameters:
  ///   - interface: The invocation contract implemented by the artifact.
  ///   - artifact: The artifact path before provider layout is applied.
  ///   - architecture: The artifact's instruction-set architecture.
  ///   - entryPoint: The provider-visible bootstrap, handler, or exported function name.
  ///   - hostAdapter: Generated glue that connects the artifact to its deployment host. A core
  ///     WebAssembly module requires one.
  ///   - environment: Environment-variable names the runtime may read. Names are deduplicated and
  ///     sorted; values are never emitted.
  ///   - toolchain: The compiler or SDK requirement used to produce the artifact.
  ///   - containerImage: The build or execution container image required by the provider.
  ///   - maximumDurationMilliseconds: A positive invocation limit, in milliseconds.
  ///   - maximumMemoryMebibytes: A positive memory limit, in mebibytes.
  ///   - maximumArtifactBytes: A positive artifact-size limit, in bytes.
  /// - Throws: ``BuildError/invalidRuntimeConfiguration(_:)`` for incompatible or unsafe values.
  public init(
    _ interface: Interface,
    artifact: String,
    architecture: Architecture,
    entryPoint: String? = nil,
    hostAdapter: String? = nil,
    environment: [String] = [],
    toolchain: String? = nil,
    containerImage: String? = nil,
    maximumDurationMilliseconds: Int? = nil,
    maximumMemoryMebibytes: Int? = nil,
    maximumArtifactBytes: Int? = nil
  ) throws {
    guard BuildArtifact.isValid(artifact) else {
      throw BuildError.invalidRuntimeConfiguration(artifact)
    }
    guard entryPoint?.contains(where: { !$0.isWhitespace }) != false else {
      throw BuildError.invalidRuntimeConfiguration(entryPoint ?? "")
    }
    guard hostAdapter.map(BuildArtifact.isValid) != false else {
      throw BuildError.invalidRuntimeConfiguration(hostAdapter ?? "")
    }
    for (name, value) in [
      ("maximumDurationMilliseconds", maximumDurationMilliseconds),
      ("maximumMemoryMebibytes", maximumMemoryMebibytes),
      ("maximumArtifactBytes", maximumArtifactBytes),
    ] where value.map({ $0 > 0 }) == false {
      throw BuildError.invalidRuntimeConfiguration(name)
    }
    let webAssembly = interface == .wasiHTTP || interface == .webAssembly
    guard webAssembly == (architecture == .wasm32) else {
      throw BuildError.invalidRuntimeConfiguration("\(interface.rawValue):\(architecture.rawValue)")
    }
    guard interface != .webAssembly || hostAdapter != nil else {
      throw BuildError.invalidRuntimeConfiguration("hostAdapter")
    }
    guard environment.allSatisfy(Self.isEnvironmentName) else {
      throw BuildError.invalidRuntimeConfiguration("environment")
    }
    guard
      [toolchain, containerImage].allSatisfy({
        $0?.contains(where: { !$0.isWhitespace }) != false
      })
    else {
      throw BuildError.invalidRuntimeConfiguration("toolchain or containerImage")
    }
    self.interface = interface
    self.artifact = artifact
    self.architecture = architecture
    self.entryPoint = entryPoint
    self.hostAdapter = hostAdapter
    self.environment = Array(Set(environment)).sorted()
    self.toolchain = toolchain
    self.containerImage = containerImage
    self.maximumDurationMilliseconds = maximumDurationMilliseconds
    self.maximumMemoryMebibytes = maximumMemoryMebibytes
    self.maximumArtifactBytes = maximumArtifactBytes
  }

  func replacingArtifacts(artifact: String, hostAdapter: String?) throws -> Self {
    try Self(
      interface,
      artifact: artifact,
      architecture: architecture,
      entryPoint: entryPoint,
      hostAdapter: hostAdapter,
      environment: environment,
      toolchain: toolchain,
      containerImage: containerImage,
      maximumDurationMilliseconds: maximumDurationMilliseconds,
      maximumMemoryMebibytes: maximumMemoryMebibytes,
      maximumArtifactBytes: maximumArtifactBytes
    )
  }

  private static func isEnvironmentName(_ value: String) -> Bool {
    guard let first = value.utf8.first,
      first == 95 || (65...90).contains(first) || (97...122).contains(first)
    else { return false }
    return value.utf8.dropFirst().allSatisfy {
      $0 == 95 || (48...57).contains($0) || (65...90).contains($0) || (97...122).contains($0)
    }
  }
}
