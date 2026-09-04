// swift-tools-version: 6.3

import PackageDescription

let swiftSettings: [SwiftSetting] = [
  .enableUpcomingFeature("NonisolatedNonsendingByDefault"),
  .enableUpcomingFeature("ImmutableWeakCaptures"),
  .strictMemorySafety(),
  .unsafeFlags(["-warnings-as-errors"]),
]

let package = Package(
  name: "__PROJECT__",
  platforms: [.macOS(.v14)],
  dependencies: [
    .package(path: "../..")
  ],
  targets: [
    .executableTarget(
      name: "__PROJECT__",
      dependencies: [
        .product(name: "RobinContent", package: "robin"),
        .product(name: "RobinCore", package: "robin"),
        .product(name: "RobinHTML", package: "robin"),
        .product(name: "RobinRouting", package: "robin"),
        .product(name: "RobinServer", package: "robin"),
        .product(name: "RobinStyle", package: "robin"),
      ],
      resources: [.process("Resources")],
      swiftSettings: swiftSettings
    ),
    .testTarget(
      name: "__PROJECT__Tests",
      dependencies: [
        "__PROJECT__",
        .product(name: "RobinTesting", package: "robin"),
      ],
      swiftSettings: swiftSettings
    ),
  ],
  swiftLanguageModes: [.v6]
)
