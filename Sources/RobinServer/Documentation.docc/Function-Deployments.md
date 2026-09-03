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
| AWS Lambda | Native Lambda | API Gateway or Function URL codec and invocation channel | Codec implemented; live validation pending |
| [Vercel Functions](https://vercel.com/docs/functions) | Native or WebAssembly | Generated Rust function bridge or JavaScript wrapper [importing precompiled Wasm](https://vercel.com/docs/functions/runtimes/wasm) | Adapter-backed; validation pending |
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
