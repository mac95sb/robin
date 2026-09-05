# ``RobinAuth``

Add passwordless authentication and authorization to a Robin server application.

## Overview

RobinAuth uses passkeys as its built-in authentication method. ``PasskeyService`` delegates WebAuthn validation to `swift-webauthn` and stores challenges, credentials, accounts, and sessions through ``AuthStore``. Use ``PasskeyClientModule`` only on pages that run a passkey ceremony.

Register ``PasskeyController`` for the browser sign-up, sign-in, and sign-out endpoints. The
`dashboard` and `realtime-chat` starters show this composition with durable SQLite sessions.
Open their local pages at `http://localhost:8080/en`; change the relying-party configuration and
allowed origins together before deployment. Passkey verification requires JavaScript and a
browser authenticator. Existing authenticated sessions continue to support ordinary HTML requests
with JavaScript disabled; email magic links provide an optional alternative sign-in mechanism.

Create one store and session issuer, then share them with the passkey service:

```swift
import Foundation
import RobinAuth
import RobinData

let database = try await SQLiteDatabase(storage: .file(path: "/srv/app/auth.sqlite"))
let keyValues = try await DatabaseKeyValueStore(database: database)
let authStore = AuthStore(keyValues)
let sessions = AuthSessionManager(store: authStore)
let passkeys = PasskeyService(
  configuration: try PasskeyConfiguration(
    relyingPartyID: "example.com",
    relyingPartyName: "Example",
    origin: URL(string: "https://example.com")!),
  store: authStore,
  sessions: sessions)
```

Email magic links are opt-in through ``MagicLinkService``. They use a RobinEmail sender, are signed and stored as hashes, and can be consumed only once. Services accept a `now` closure for deterministic expiration tests.

Apply `Middleware.authSessions(_:store:cookieName:)` before `Middleware.authorization(_:store:)` to resolve secure session cookies and enforce application-defined permissions. Use RobinServer's security middleware to validate the double-submit CSRF token created by ``CSRFToken``.

## Topics

### Passkeys

- ``PasskeyController``
- ``PasskeyConfiguration``
- ``PasskeyService``
- ``PasskeyRegistrationCeremony``
- ``PasskeyAuthenticationCeremony``
- ``PasskeyCredential``
- ``PasskeyClientModule``
- ``RecoveryPolicy``

### Magic links

- ``MagicLinkConfiguration``
- ``MagicLinkService``
- ``MagicLinkPurpose``
- ``MagicLinkConsumption``

### Accounts and sessions

- ``Account``
- ``AuthStore``
- ``AuthSessionManager``
- ``AuthSession``
- ``SessionToken``
- ``CSRFToken``

### Authorization and security

- ``AuthPrincipal``
- ``Role``
- ``Permission``
- ``TrustedProxyPolicy``
- ``AuthAuditEvent``
- ``AuthError``
