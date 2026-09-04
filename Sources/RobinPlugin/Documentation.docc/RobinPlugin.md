# ``RobinPlugin``

Extend Robin through compatibility-checked, capability-specific contracts.

## Overview

A plugin adopts ``Plugin`` and only the capability protocols it implements. Robin checks the
plugin's ``Plugin/supportedPluginAPIVersions`` before using those capabilities.

```swift
import RobinBuild
import RobinPlugin

struct BrandAssets: AssetPlugin {
  let assets: [BuildAsset]
}

try BrandAssets.validateCompatibility()
```

Build-time capabilities contribute assets, generated Swift, artifact transforms, Markdown stages,
or design tokens. Runtime capabilities contribute routes, middleware, typed services, lifecycle
work, or command-line commands.

## Topics

### Compatibility

- ``Plugin``
- ``PluginAPIVersion``
- ``PluginCompatibilityError``

### Build capabilities

- ``AssetPlugin``
- ``BuildTransformPlugin``
- ``GeneratedSource``
- ``SourceGenerationPlugin``
- ``MarkdownPlugin``
- ``StylePlugin``

### Runtime capabilities

- ``RoutePlugin``
- ``MiddlewarePlugin``
- ``ServicePlugin``
- ``LifecyclePlugin``
- ``CommandPlugin``

