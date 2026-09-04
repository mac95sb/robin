/// A plugin that generates type-checked Swift source before a build.
public protocol SourceGenerationPlugin: Plugin {
  /// Produces source files beneath Robin's generated source root.
  ///
  /// - Returns: Generated Swift source files.
  /// - Throws: An error raised while generating source.
  func generateSources() async throws -> [GeneratedSource]
}
