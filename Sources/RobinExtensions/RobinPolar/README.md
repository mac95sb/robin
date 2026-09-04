# RobinPolar

RobinPolar adds typed checkout and subscription calls plus a verified, durable webhook route.

```swift
import RobinCore
import RobinPolar

let client = try PolarClient(accessToken: Secret(environment.POLAR_ACCESS_TOKEN))
let plugin = try PolarPlugin(
  client: client,
  webhookSecret: Secret(environment.POLAR_WEBHOOK_SECRET),
  jobs: jobs
)
```

Register `plugin.routes` with the application and call `plugin.registerServices(in:)` during service
configuration. Webhooks are acknowledged only after `PolarWebhookJob` is durably enqueued with the
Polar delivery identifier as its idempotency key.
