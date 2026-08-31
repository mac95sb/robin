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
    .library(name: "RobinRendering", targets: ["RobinRendering"]),
    .library(name: "RobinContent", targets: ["RobinContent"]),
    .library(name: "RobinForms", targets: ["RobinForms"]),
    .library(name: "RobinRouting", targets: ["RobinRouting"]),
    .library(name: "RobinRuntime", targets: ["RobinRuntime"]),
    .library(name: "RobinStyling", targets: ["RobinStyling"]),
    .library(name: "RobinStreaming", targets: ["RobinStreaming"]),
    .library(name: "RobinTooling", targets: ["RobinTooling"]),
  ],
  dependencies: [
    .package(url: "https://github.com/vapor/sqlite-nio.git", from: "1.10.0"),
    .package(url: "https://github.com/vapor/postgres-nio.git", from: "1.33.0"),
    .package(url: "https://github.com/brokenhandsio/swift-webauthn.git", from: "1.0.0-alpha.2"),
    .package(url: "https://github.com/tuist/Noora.git", from: "0.17.0"),
    .package(url: "https://github.com/apple/swift-nio.git", from: "2.101.0"),
    .package(url: "https://github.com/swiftlang/swift-markdown.git", from: "0.8.0"),
    .package(url: "https://github.com/apple/swift-collections.git", from: "1.6.0"),
    .package(url: "https://github.com/swiftlang/swift-syntax.git", from: "603.0.0"),
    .package(url: "https://github.com/apple/swift-openapi-generator.git", from: "1.0.0"),
    .package(url: "https://github.com/apple/swift-openapi-runtime.git", from: "1.0.0"),
  ],
  targets: [
    .target(
      name: "RobinCore",
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
      dependencies: ["RobinCore", "RobinHTML"],
      swiftSettings: upcomingFeatures
    ),
    .macro(
      name: "RobinMacros",
      dependencies: [
        .product(name: "SwiftCompilerPlugin", package: "swift-syntax"),
        .product(name: "SwiftSyntax", package: "swift-syntax"),
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
      name: "RobinRendering",
      swiftSettings: lowLevelFeatures
    ),
    .target(
      name: "RobinContent",
      dependencies: [
        "RobinRendering",
        .product(name: "Markdown", package: "swift-markdown"),
      ],
      swiftSettings: lowLevelFeatures
    ),
    .target(
      name: "RobinForms",
      dependencies: ["RobinMacros", "RobinRendering"],
      swiftSettings: lowLevelFeatures
    ),
    .target(
      name: "RobinRouting",
      dependencies: ["RobinCore"],
      swiftSettings: lowLevelFeatures
    ),
    .target(
      name: "RobinRoutingValidation",
      dependencies: [
        "RobinRendering",
        .product(name: "NIOHTTP1", package: "swift-nio"),
      ],
      swiftSettings: lowLevelFeatures
    ),
    .target(
      name: "RobinRuntime",
      swiftSettings: lowLevelFeatures
    ),
    .target(
      name: "RobinStyling",
      dependencies: [
        .product(name: "OrderedCollections", package: "swift-collections")
      ],
      swiftSettings: lowLevelFeatures
    ),
    .target(
      name: "RobinStreaming",
      dependencies: [
        "RobinRendering",
        "RobinRoutingValidation",
        .product(name: "NIOCore", package: "swift-nio"),
        .product(name: "NIOHTTP1", package: "swift-nio"),
      ],
      swiftSettings: lowLevelFeatures
    ),
    .target(
      name: "RobinTooling",
      dependencies: ["RobinCore"],
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
      name: "RobinRenderingTests",
      dependencies: ["RobinRendering"],
      swiftSettings: upcomingFeatures
    ),
    .testTarget(
      name: "RobinContentTests",
      dependencies: ["RobinContent", "RobinRendering"],
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
      name: "RobinRoutingValidationTests",
      dependencies: ["RobinRendering", "RobinRoutingValidation"],
      swiftSettings: upcomingFeatures
    ),
    .testTarget(
      name: "RobinRuntimeTests",
      dependencies: ["RobinRuntime"],
      swiftSettings: upcomingFeatures
    ),
    .testTarget(
      name: "RobinStylingTests",
      dependencies: ["RobinStyling"],
      swiftSettings: upcomingFeatures
    ),
    .testTarget(
      name: "RobinStreamingTests",
      dependencies: [
        "RobinRendering",
        "RobinRoutingValidation",
        "RobinStreaming",
        .product(name: "NIOCore", package: "swift-nio"),
        .product(name: "NIOEmbedded", package: "swift-nio"),
        .product(name: "NIOHTTP1", package: "swift-nio"),
      ],
      swiftSettings: upcomingFeatures
    ),
    .testTarget(
      name: "RobinToolingTests",
      dependencies: ["RobinCore", "RobinTooling"],
      resources: [.copy("Fixtures")],
      swiftSettings: upcomingFeatures
    ),
  ],
  swiftLanguageModes: [.v6]
)
