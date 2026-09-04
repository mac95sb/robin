# Run Functions with Lambda and WASI

Use one application responder with persistent servers, invocation APIs, and WebAssembly hosts.

## Overview

Robin treats Lambda and WASI as deployment runtimes for API and SSR applications, not application
modes. Static applications produce files for a static host or CDN and never use either runtime.
Choosing a runtime does not change an application's inferred mode or declaration.

### Handle Lambda events

``AWSLambdaHTTPEventCodec`` supports API Gateway payload formats 1.0 and 2.0, including Lambda
Function URLs. It preserves query parameters, repeated headers, cookies, text bodies, and binary
bodies while translating the provider envelope to ``Request`` and ``Response``.

```swift
let runtime = try InvocationRuntime(
  Site(),
  codec: AWSLambdaHTTPEventCodec(payloadVersion: .v2)
)
try await runtime.run(using: channel)
```

An ``InvocationChannel`` owns the provider's receive, success, and failure endpoints. Custom
providers normally need only a channel and an ``InvocationEventCodec``; they do not need another
Robin framework module.

The standard `RobinApplication.run(Self())` entry point detects `AWS_LAMBDA_RUNTIME_API` and uses
``AWSLambdaRuntimeAPIChannel`` with payload format 2.0 automatically. Other providers call the same
public runtime with their channel and codec from generated host glue.

### Handle WASI HTTP

``WASIRuntime`` accepts generated `wasi:http` bindings through ``WASIHostAdapter``. Hosts limited to
core WebAssembly modules can implement the same adapter contract in a small generated wrapper.

```swift
let runtime = try WASIRuntime(Site(), adapter: generatedAdapter)
let response = try await runtime.respond(to: incomingRequest)
```

Invocation and WASI runtimes guarantee buffered request and response bodies. Routes that require
streaming, server-sent events, WebSockets, process-local state, or a persistent filesystem fail when
the responder starts. A returned streaming, file, event, or WebSocket body fails during encoding.

## Provider compatibility

The categories describe integration shape, not a promise that Robin maintains a provider-specific
package. Provider profiles and live smoke tests promote entries from experimental to verified.

| Provider or host | Output | Integration | Status |
| --- | --- | --- | --- |
| AWS Lambda | Native Lambda | API Gateway or Function URL codec and invocation channel | Local codec conformance verified; emulator and live validation pending |
| [Vercel Functions](https://vercel.com/docs/functions) | WebAssembly | Official Build Output API with an Edge JavaScript adapter importing precompiled Wasm | Output profile verified; live Robin adapter validation pending |
| Azure Functions | Native | Custom handler | Adapter-backed; validation pending |
| Google Cloud Run functions and Cloud Run | Native or WASI | Custom runtime or container | Adapter-backed; validation pending |
| Alibaba Cloud Function Compute | Native or WASI | Custom runtime or container | Adapter-backed; validation pending |
| Tencent Cloud Functions | Native or WASI | Custom runtime or image | Adapter-backed; validation pending |
| Oracle Cloud Functions and Fn Project | Native or WASI | Function container | Adapter-backed; validation pending |
| Apache OpenWhisk | Native or WASI | Custom runtime action | Adapter-backed; validation pending |
| Knative, OpenFaaS, and Fission | Native or WASI | Function container | Adapter-backed; validation pending |
| Fastly Compute | WASI | Native WebAssembly host contract | Experimental |
| Fermyon Spin and SpinKube | WASI component | `wasi:http` host bindings | Experimental |
| wasmCloud and Golem | WASI component | Component host bindings | Experimental |
| Wasmtime, WasmEdge, and Wasmer | WASI or core WebAssembly | Embedded or standalone host adapter | Experimental |
| Cloudflare Workers | Core WebAssembly | Generated JavaScript host adapter | Experimental |
| Deno Deploy | Core WebAssembly | Generated JavaScript host adapter | Experimental |
| Netlify Edge Functions | Core WebAssembly | Generated JavaScript host adapter | Experimental |

> Important: Vercel Edge Functions and other JavaScript-isolate hosts do not consume a native
> Lambda executable. They require WebAssembly output and a host adapter.

## Package runtime artifacts

`DeploymentRuntime` records the interface, architecture, artifact, host adapter, environment names,
entry point, and resource limits without storing environment values. `BuildPipeline` validates the
configuration and writes deterministic deployment metadata beneath `.robin/build`.

```swift
let configuration = BuildConfiguration(
  runtimeArtifacts: [lambdaArtifact, wasiArtifact, adapterArtifact],
  runtimes: [
    try DeploymentRuntime(
      .lambda,
      artifact: "bootstrap",
      architecture: .arm64,
      entryPoint: "bootstrap"
    ),
    try DeploymentRuntime(
      .wasiHTTP,
      artifact: "site.wasm",
      architecture: .wasm32,
      entryPoint: "wasi:http/incoming-handler",
      hostAdapter: "adapter.js"
    ),
  ]
)
```

Use `ArtifactLayout` and `RoutingManifestEncoder` to map the neutral graph to a provider filesystem
and routing format. Robin always records the neutral runtime contract in `deployment.json`.

## Configure an AWS Lambda profile

AWS custom runtimes require an executable named `bootstrap` at the deployment-package root. Build
for the selected Linux architecture and keep the provider settings visible in ordinary
`BuildConfiguration`:

```swift
let aws = BuildConfiguration(
  runtimeArtifacts: [bootstrap, swiftCore],
  artifactLayout: .init(),
  runtimes: [
    try DeploymentRuntime(
      .lambda,
      artifact: "bootstrap",
      architecture: .arm64,
      entryPoint: "bootstrap",
      environment: ["DATABASE_URL"],
      toolchain: "Swift 6.3.3 Linux",
      containerImage: "swift:6.3.3-amazonlinux2",
      maximumDurationMilliseconds: 30_000,
      maximumMemoryMebibytes: 512
    )
  ]
)
```

Package `bootstrap` and every runtime-library dependency at the archive root, preserve executable
permissions, and select an OS-only Lambda runtime. API Gateway HTTP API and Function URLs use
``AWSLambdaHTTPEventCodec`` payload format 2.0 by default; select 1.0 only for an API Gateway REST
API that sends that envelope. AWS documents the custom-runtime entry point in its
[runtime guide](https://docs.aws.amazon.com/lambda/latest/dg/runtimes-custom.html).

## Configure a Vercel profile

Vercel's Build Output API is a filesystem contract rather than a Robin runtime. Use
`ArtifactLayout` to place static files under `.vercel/output/static` and a generated host adapter
plus WebAssembly artifact under `.vercel/output/functions/robin.func`. Use
`VercelRoutingManifestEncoder` for `.vercel/output/config.json` and include the function's
required `.vc-config.json` as deployment metadata. Keep the expanded configuration in source
control; a named provider package is unnecessary.

Vercel Build Output API version 3 requires `.vercel/output/config.json`, and each function lives in
a directory ending in `.func`. Its official
[configuration](https://vercel.com/docs/build-output-api/configuration) and
[function primitive](https://vercel.com/docs/build-output-api/primitives) references are the
authority for those files. Native Swift executables are not a portable Vercel profile; build the
WebAssembly artifact and adapter on the target toolchain and validate the complete output before
deployment.

The provider conformance workflow pins Swift 6.3.3, verifies the official WASI SDK by checksum,
compiles a WASI fixture, checks the versioned Build Output API fixture, and runs the shared
persistent/Lambda/WASI HTTP suite without credentials. It pins Vercel CLI 59.10.0. Live AWS and
Vercel deployment, cleanup, and performance measurements are final-release checks, run from
protected environments with minimum-permission credentials rather than on ordinary changes.

## Invocation-runtime limits

Lambda-style and WebAssembly profiles buffer request and response bodies and reject WebSockets,
server-sent events, response streaming, process-local coordination, workers, and persistent local
filesystems. Put durable state in external services, make jobs idempotent, keep initialization
reusable across warm invocations, and treat cancellation and deadlines as normal request outcomes.
Choose a persistent deployment when the application needs any rejected capability.
