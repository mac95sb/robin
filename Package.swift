// swift-tools-version: 6.3

import CompilerPluginSupport
import PackageDescription

let upcomingFeatures: [SwiftSetting] = [
  .enableUpcomingFeature("NonisolatedNonsendingByDefault"),
  .enableUpcomingFeature("ImmutableWeakCaptures"),
]

let lowLevelFeatures =
  upcomingFeatures + [
    .strictMemorySafety(),
    .unsafeFlags(["-warnings-as-errors"]),
  ]

let package = Package(
  name: "robin",
  platforms: [.macOS(.v14)],
  products: [
    .library(name: "RobinCore", targets: ["RobinCore"]),
    .library(name: "RobinHTML", targets: ["RobinHTML"]),
    .library(name: "RobinStyle", targets: ["RobinStyle"]),
    .library(name: "RobinContent", targets: ["RobinContent"]),
    .library(name: "RobinForms", targets: ["RobinForms"]),
    .library(name: "RobinRouting", targets: ["RobinRouting"]),
    .library(name: "RobinRuntime", targets: ["RobinRuntime"]),
    .library(name: "RobinServer", targets: ["RobinServer"]),
    .library(name: "RobinBuild", targets: ["RobinBuild"]),
    .library(name: "RobinTesting", targets: ["RobinTesting"]),
    .library(name: "RobinTooling", targets: ["RobinTooling"]),
    .executable(name: "robin", targets: ["RobinCLI"]),
  ],
  dependencies: [
    .package(url: "https://github.com/vapor/sqlite-nio.git", from: "1.10.0"),
    .package(url: "https://github.com/vapor/postgres-nio.git", from: "1.33.0"),
    .package(url: "https://github.com/brokenhandsio/swift-webauthn.git", from: "1.0.0-alpha.2"),
    .package(url: "https://github.com/tuist/Noora.git", from: "0.17.0"),
    .package(url: "https://github.com/apple/swift-argument-parser", from: "1.8.2"),
    .package(url: "https://github.com/apple/swift-nio.git", from: "2.101.0"),
    .package(url: "https://github.com/apple/swift-nio-ssl.git", from: "2.37.0"),
    .package(url: "https://github.com/apple/swift-nio-http2.git", from: "1.44.0"),
    .package(url: "https://github.com/apple/swift-nio-extras.git", from: "1.34.0"),
    .package(url: "https://github.com/apple/swift-http-types.git", from: "1.6.0"),
    .package(url: "https://github.com/apple/swift-http-structured-headers.git", from: "1.7.0"),
    .package(url: "https://github.com/apple/swift-log.git", from: "1.6.0"),
    .package(url: "https://github.com/apple/swift-metrics.git", from: "2.7.0"),
    .package(url: "https://github.com/swift-server/swift-prometheus.git", from: "2.3.0"),
    .package(url: "https://github.com/apple/swift-distributed-tracing.git", from: "1.4.1"),
    .package(url: "https://github.com/apple/swift-service-context.git", from: "1.3.0"),
    .package(url: "https://github.com/swift-server/swift-service-lifecycle.git", from: "2.11.0"),
    .package(url: "https://github.com/apple/swift-crypto.git", from: "4.5.0"),
    .package(url: "https://github.com/apple/swift-collections.git", from: "1.3.0"),
    .package(url: "https://github.com/apple/swift-system.git", from: "1.8.0"),
    .package(url: "https://github.com/swiftlang/swift-markdown.git", from: "0.8.0"),
    .package(url: "https://github.com/swiftlang/swift-syntax.git", from: "603.0.0"),
    .package(url: "https://github.com/swiftlang/swift-docc-plugin.git", from: "1.5.0"),
    .package(url: "https://github.com/apple/swift-openapi-generator.git", from: "1.0.0"),
    .package(url: "https://github.com/apple/swift-openapi-runtime.git", from: "1.0.0"),
  ],
  targets: [
    .target(
      name: "RobinCore",
      dependencies: [.product(name: "SystemPackage", package: "swift-system")],
      swiftSettings: lowLevelFeatures
    ),
    .target(
      name: "RobinOwnershipValidation",
      dependencies: [.product(name: "NIOCore", package: "swift-nio")],
      swiftSettings: lowLevelFeatures
    ),
    .target(
      name: "RobinHTML",
      dependencies: ["RobinCore"],
      swiftSettings: upcomingFeatures
    ),
    .target(
      name: "RobinStyle",
      dependencies: [
        "RobinCore",
        "RobinHTML",
        "RobinMacros",
        .product(name: "Crypto", package: "swift-crypto"),
      ],
      swiftSettings: upcomingFeatures
    ),
    .macro(
      name: "RobinMacros",
      dependencies: [
        .product(name: "SwiftCompilerPlugin", package: "swift-syntax"),
        .product(name: "SwiftSyntax", package: "swift-syntax"),
        .product(name: "SwiftSyntaxBuilder", package: "swift-syntax"),
        .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
      ],
      swiftSettings: lowLevelFeatures
    ),
    .target(
      name: "OpenAPIGeneratorValidation",
      dependencies: [
        .product(name: "OpenAPIRuntime", package: "swift-openapi-runtime")
      ],
      swiftSettings: upcomingFeatures,
      plugins: [
        .plugin(name: "OpenAPIGenerator", package: "swift-openapi-generator")
      ]
    ),
    .target(
      name: "RobinContent",
      dependencies: [
        .product(name: "Markdown", package: "swift-markdown")
      ],
      swiftSettings: lowLevelFeatures
    ),
    .target(
      name: "RobinForms",
      dependencies: ["RobinHTML", "RobinMacros"],
      swiftSettings: lowLevelFeatures
    ),
    .target(
      name: "RobinRouting",
      dependencies: ["RobinCore"],
      swiftSettings: lowLevelFeatures
    ),
    .target(
      name: "RobinRuntime",
      swiftSettings: lowLevelFeatures
    ),
    .target(
      name: "RobinServer",
      dependencies: [
        "RobinBuild",
        "RobinCore",
        "RobinHTML",
        "RobinRouting",
        .product(name: "HTTPTypes", package: "swift-http-types"),
        .product(name: "StructuredFieldValues", package: "swift-http-structured-headers"),
        .product(name: "Logging", package: "swift-log"),
        .product(name: "Metrics", package: "swift-metrics"),
        .product(name: "Prometheus", package: "swift-prometheus"),
        .product(name: "Tracing", package: "swift-distributed-tracing"),
        .product(name: "ServiceContextModule", package: "swift-service-context"),
        .product(name: "ServiceLifecycle", package: "swift-service-lifecycle"),
        .product(name: "Crypto", package: "swift-crypto"),
        .product(name: "Collections", package: "swift-collections"),
        .product(name: "SystemPackage", package: "swift-system"),
        .product(name: "NIOCore", package: "swift-nio"),
        .product(name: "NIOConcurrencyHelpers", package: "swift-nio"),
        .product(name: "NIOHTTP1", package: "swift-nio"),
        .product(name: "NIOPosix", package: "swift-nio"),
        .product(name: "NIOWebSocket", package: "swift-nio"),
        .product(name: "NIOSSL", package: "swift-nio-ssl"),
        .product(name: "NIOHTTP2", package: "swift-nio-http2"),
        .product(name: "NIOExtras", package: "swift-nio-extras"),
        .product(name: "NIOHTTPTypesHTTP1", package: "swift-nio-extras"),
      ],
      swiftSettings: lowLevelFeatures
    ),
    .target(
      name: "RobinBuild",
      dependencies: [
        "RobinContent",
        "RobinCore",
        "RobinHTML",
        "RobinStyle",
        .product(name: "Crypto", package: "swift-crypto"),
      ],
      swiftSettings: lowLevelFeatures
    ),
    .target(
      name: "RobinTooling",
      dependencies: ["RobinBuild", "RobinCore"],
      swiftSettings: lowLevelFeatures
    ),
    .target(
      name: "RobinTesting",
      dependencies: [
        "RobinCore",
        "RobinHTML",
        "RobinMacros",
        "RobinServer",
        "RobinStyle",
      ],
      swiftSettings: lowLevelFeatures
    ),
    .executableTarget(
      name: "RobinCLI",
      dependencies: [
        "RobinCore",
        "RobinTooling",
        .product(name: "ArgumentParser", package: "swift-argument-parser"),
        .product(name: "Noora", package: "Noora"),
      ],
      swiftSettings: lowLevelFeatures
    ),
    .testTarget(
      name: "RobinCoreTests",
      dependencies: ["RobinCore"],
      swiftSettings: upcomingFeatures
    ),
    .testTarget(
      name: "RobinOwnershipValidationTests",
      dependencies: [
        "RobinOwnershipValidation",
        .product(name: "NIOCore", package: "swift-nio"),
      ],
      swiftSettings: upcomingFeatures
    ),
    .testTarget(
      name: "RobinHTMLTests",
      dependencies: ["RobinCore", "RobinHTML"],
      swiftSettings: upcomingFeatures
    ),
    .testTarget(
      name: "RobinStyleTests",
      dependencies: ["RobinCore", "RobinHTML", "RobinStyle"],
      swiftSettings: upcomingFeatures
    ),
    .testTarget(
      name: "ExceptionDependencyLinkTests",
      dependencies: [
        .product(name: "SQLiteNIO", package: "sqlite-nio"),
        .product(name: "PostgresNIO", package: "postgres-nio"),
        .product(name: "WebAuthn", package: "swift-webauthn"),
        .product(name: "Noora", package: "Noora"),
      ],
      swiftSettings: upcomingFeatures
    ),
    .testTarget(
      name: "RobinContentTests",
      dependencies: ["RobinContent"],
      resources: [.copy("Fixtures")],
      swiftSettings: upcomingFeatures
    ),
    .testTarget(
      name: "RobinFormsTests",
      dependencies: ["RobinForms"],
      swiftSettings: upcomingFeatures
    ),
    .testTarget(
      name: "RobinRoutingTests",
      dependencies: ["RobinRouting"],
      swiftSettings: upcomingFeatures
    ),
    .testTarget(
      name: "RobinRuntimeTests",
      dependencies: ["RobinRuntime"],
      swiftSettings: upcomingFeatures
    ),
    .testTarget(
      name: "RobinServerTests",
      dependencies: [
        "RobinCore",
        "RobinHTML",
        "RobinRouting",
        "RobinServer",
        .product(name: "Crypto", package: "swift-crypto"),
        .product(name: "HTTPTypes", package: "swift-http-types"),
        .product(name: "NIOCore", package: "swift-nio"),
        .product(name: "NIOEmbedded", package: "swift-nio"),
        .product(name: "NIOHTTP1", package: "swift-nio"),
      ],
      swiftSettings: upcomingFeatures
    ),
    .testTarget(
      name: "RobinBuildTests",
      dependencies: [
        "RobinBuild", "RobinCore", "RobinHTML", "RobinStyle",
        .product(name: "Crypto", package: "swift-crypto"),
      ],
      swiftSettings: upcomingFeatures
    ),
    .testTarget(
      name: "RobinToolingTests",
      dependencies: [
        "RobinBuild", "RobinCLI", "RobinCore", "RobinTooling",
        .product(name: "ArgumentParser", package: "swift-argument-parser"),
      ],
      resources: [.copy("Fixtures")],
      swiftSettings: upcomingFeatures
    ),
    .testTarget(
      name: "RobinTestingTests",
      dependencies: [
        "RobinBuild", "RobinCore", "RobinHTML", "RobinServer", "RobinTesting", "RobinStyle",
        .product(name: "HTTPTypes", package: "swift-http-types"),
      ],
      swiftSettings: upcomingFeatures
    ),
  ],
  swiftLanguageModes: [.v6]
)
