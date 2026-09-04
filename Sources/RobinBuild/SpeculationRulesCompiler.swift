import Foundation
import RobinHTML

struct CompiledSpeculationRules {
  let artifact: BuildArtifact?
  let headElement: String?
}

struct SpeculationRulesCompiler {
  static func compile(
    _ rules: [SpeculationRule],
    pagePaths: Set<String>,
    assets: ProcessedAssets
  ) throws -> CompiledSpeculationRules {
    guard !rules.isEmpty else { return .init(artifact: nil, headElement: nil) }
    for rule in rules {
      guard pagePaths.contains(rule.path) else {
        throw BuildError.unknownSpeculationRoute(rule.path)
      }
      for reference in rule.requiredAssets where assets.references[reference] == nil {
        throw BuildError.unknownSpeculationAsset(reference)
      }
    }
    let ordered = Array(Set(rules)).sorted {
      ($0.action.rawValue, $0.path, $0.eagerness.rawValue)
        < ($1.action.rawValue, $1.path, $1.eagerness.rawValue)
    }
    struct Candidate: Encodable {
      let urls: [String]
      let eagerness: String
    }
    struct Rules: Encodable {
      let prefetch: [Candidate]?
      let prerender: [Candidate]?
    }
    let grouped = Dictionary(grouping: ordered, by: \.action)
    let payload = Rules(
      prefetch: grouped[.prefetch].map {
        $0.map { Candidate(urls: [$0.path], eagerness: $0.eagerness.rawValue) }
      },
      prerender: grouped[.prerender].map {
        $0.map { Candidate(urls: [$0.path], eagerness: $0.eagerness.rawValue) }
      }
    )
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.sortedKeys]
    let data = try encoder.encode(payload)
    let dependencies = ordered.flatMap(\.requiredAssets).compactMap {
      assets.references[$0]?.artifact.path
    }
    let artifact = try BuildArtifact(
      kind: .deploymentMetadata,
      path: "speculation-rules.json",
      bytes: Array(data),
      dependencies: dependencies,
      mediaType: "application/speculationrules+json"
    )
    let scriptData = String(decoding: data, as: UTF8.self)
      .replacingOccurrences(of: "<", with: "\\u003c")
    return .init(
      artifact: artifact,
      headElement: "<script type=\"speculationrules\">\(scriptData)</script>"
    )
  }
}
