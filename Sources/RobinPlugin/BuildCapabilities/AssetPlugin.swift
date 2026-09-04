import RobinBuild

/// A plugin that contributes assets to a Robin build.
public protocol AssetPlugin: Plugin {
  /// Assets to process with the application's assets.
  var assets: [BuildAsset] { get }
}
