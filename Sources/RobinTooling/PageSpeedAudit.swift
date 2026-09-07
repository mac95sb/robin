import Foundation

#if canImport(FoundationNetworking)
  import FoundationNetworking
#endif

package enum PageSpeedAudit {
  package enum Strategy: String, Sendable { case mobile, desktop }

  package static func request(url: String, strategy: Strategy, key: String?) throws -> URLRequest {
    guard let site = URLComponents(string: url),
      ["https", "http"].contains(site.scheme?.lowercased() ?? ""),
      let host = site.host, !host.isEmpty, site.user == nil, site.password == nil
    else { throw URLError(.badURL) }
    var endpoint = URLComponents(
      string: "https://www.googleapis.com/pagespeedonline/v5/runPagespeed")!
    endpoint.queryItems = [
      .init(name: "url", value: url), .init(name: "strategy", value: strategy.rawValue),
      .init(name: "category", value: "performance"),
    ]
    if let key, !key.isEmpty { endpoint.queryItems?.append(.init(name: "key", value: key)) }
    guard let endpointURL = endpoint.url else { throw URLError(.badURL) }
    return URLRequest(url: endpointURL, timeoutInterval: 60)
  }

  package static func audit(url: String, strategy: Strategy) async -> [ToolDiagnostic] {
    do {
      let request = try request(
        url: url, strategy: strategy,
        key: ProcessInfo.processInfo.environment["PAGESPEED_API_KEY"])
      let (data, response) = try await URLSession.shared.data(for: request)
      guard let response = response as? HTTPURLResponse else { throw URLError(.badServerResponse) }
      guard response.statusCode == 200 else {
        return [
          failure(
            "PageSpeed Insights returned HTTP \(response.statusCode).",
            remediation: "Check Google API quota and PAGESPEED_API_KEY, then retry.")
        ]
      }
      return try diagnostics(from: data, strategy: strategy)
    } catch {
      // Network errors can include the API key in the request URL. Never print them.
      return [
        failure(
          "PageSpeed Insights could not complete the audit.",
          remediation: "Use a public HTTP(S) URL without credentials. Check connectivity and retry."
        )
      ]
    }
  }

  package static func diagnostics(from data: Data, strategy: Strategy) throws -> [ToolDiagnostic] {
    let response = try JSONDecoder().decode(Response.self, from: data)
    guard let result = response.lighthouseResult, result.runtimeError == nil,
      let score = result.categories?.performance?.score, score.isFinite, (0...1).contains(score)
    else {
      return [
        failure(
          "PageSpeed Insights did not produce a valid performance result.",
          remediation: "Ensure Google can load the URL, then retry.")
      ]
    }
    var diagnostics: [ToolDiagnostic] = [
      .init(
        code: "pagespeed-score", severity: .note,
        message: "Lighthouse performance (\(strategy.rawValue))",
        measurement: .init(value: score * 100, unit: "/100"))
    ]
    if score < 0.9 {
      diagnostics.append(
        .init(
          code: "pagespeed-performance", severity: .warning,
          message: "Lighthouse performance score is below 90/100.",
          remediation:
            "Review the reported measurements and the PageSpeed Insights recommendations."))
    }
    let metrics = [
      ("first-contentful-paint", "First contentful paint", "ms"),
      ("largest-contentful-paint", "Largest contentful paint", "ms"),
      ("total-blocking-time", "Total blocking time", "ms"),
      ("speed-index", "Speed index", "ms"),
      ("cumulative-layout-shift", "Cumulative layout shift", "score"),
    ]
    for (id, title, unit) in metrics {
      if let value = result.audits[id]?.numericValue, value.isFinite, value >= 0 {
        diagnostics.append(
          .init(
            code: id, severity: .note, message: title,
            measurement: .init(value: value, unit: unit)))
      } else {
        diagnostics.append(
          .init(
            code: "pagespeed-metric-unavailable", severity: .warning,
            message: "\(title) was unavailable; it is not counted as zero."))
      }
    }
    for (id, audit) in result.audits.sorted(by: { $0.key < $1.key })
    where audit.scoreDisplayMode == "binary" && (audit.score ?? 1) < 1 {
      diagnostics.append(
        .init(
          code: "pagespeed-\(id)", severity: .warning,
          message: audit.title ?? id,
          remediation: "Inspect this audit in PageSpeed Insights for recommendations."))
    }
    diagnostics.append(
      .init(
        code: "pagespeed-scope", severity: .note,
        message:
          "Lighthouse lab measurements for \(strategy.rawValue). Results vary between runs; these are not real-user Core Web Vitals."
      ))
    return diagnostics
  }

  private static func failure(_ message: String, remediation: String) -> ToolDiagnostic {
    .init(code: "pagespeed-failed", severity: .error, message: message, remediation: remediation)
  }

  private struct Response: Decodable {
    let lighthouseResult: Result?
    struct Result: Decodable {
      let runtimeError: RuntimeError?
      let categories: Categories?
      let audits: [String: Audit]
    }
    struct RuntimeError: Decodable { let code: String? }
    struct Categories: Decodable { let performance: Category? }
    struct Category: Decodable { let score: Double? }
    struct Audit: Decodable {
      let title: String?
      let score: Double?
      let scoreDisplayMode: String?
      let numericValue: Double?
    }
  }
}
