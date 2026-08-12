// swift-tools-version: 6.3
import PackageDescription

let upcomingFeatures: [SwiftSetting] = [
  .enableUpcomingFeature("NonisolatedNonsendingByDefault")
]

let package = Package(
  name: "robin",
  platforms: [.macOS(.v14)],
  products: [
    .library(name: "RobinCore", targets: ["RobinCore"])
  ],
  targets: [
    .target(
      name: "RobinCore",
      swiftSettings: upcomingFeatures
    ),
    .testTarget(
      name: "RobinCoreTests",
      dependencies: ["RobinCore"],
      swiftSettings: upcomingFeatures
    ),
  ]
)
