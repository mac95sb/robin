# ``RobinBuild``

Build deterministic static and executable deployment artifacts.

## Overview

RobinBuild infers an application's mode, renders static pages, compiles reachable CSS, and models
provider output as one dependency graph. Typed assets can be fingerprinted, transformed by
checksum-pinned tools, delivered through a CDN, or fetched during an asynchronous build with a
verified digest. Every generated or cached file remains beneath the project's `.robin` directory.

Use ``BuildPipeline`` synchronously for local inputs or asynchronously when the configuration
contains remote assets.
Static applications emit no Robin JavaScript unless they explicitly enable a typed runtime
capability.

```swift
import Foundation
import RobinBuild
import RobinCore

let layout = OutputLayout(
  projectRoot: URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
)
let result = try BuildPipeline.build(MySite(), in: layout)
```

Build output is available in `.robin/build`; reusable content remains in `.robin/cache`.

## Topics

### Build applications

- ``BuildPipeline``
- ``BuildConfiguration``
- ``BuildEnvironment``
- ``BuildResult``

### Artifact graphs

- ``BuildArtifact``
- ``ArtifactGraph``
- ``BuildManifest``
- ``ArtifactLayout``

### Assets and delivery

- ``BuildAsset``
- ``RemoteAsset``
- ``AssetTransform``
- ``AssetTool``
- ``AssetToolchain``
- ``ImageMetadata``
- ``ResourceHint``
- ``SpeculationRule``
- ``ScriptOrigin``

### Deployment routing

- ``DeploymentRoute``
- ``RoutingManifestEncoder``
- ``JSONRoutingManifestEncoder``

### Diagnostics

- ``BuildError``
