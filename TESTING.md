# Try Robin before the API feedback pass

Use a fresh generated project when judging the developer experience. Use the checked-in starters
when testing unpublished framework changes: their package dependency points at this checkout.
Run one server starter at a time, or assign dashboard/chat a different `PORT`.

## Start with the four journeys

Run `mise run benchmark` for release-mode render, escaping, style, route, form, query, cache,
Markdown, and incremental-build measurements. The first medians are baselines; the generous
timeout guard is not a production performance guarantee.

| Journey | Actions | Expected result |
| --- | --- | --- |
| Blog | Run `mise run dev` in `Templates/blog`; serve its `.robin/build` directory. Visit `/en/`, `/fr/`, and both About pages. | Localized titles, descriptions, links, and layouts agree. No Robin JavaScript assets are generated. |
| Dashboard | In `Templates/dashboard`, run `PORT=18080 mise run dev`; open `http://localhost:18080/en`. Create a passkey, then add, edit, and delete a note. | Sign-in reloads the page. Native forms return to the dashboard and show the saved changes. |
| Form errors | Submit an empty note, then a spaces-only note. Repeat with JavaScript disabled. | Native validation stops the empty submission. Server validation redisplays spaces-only input with an error summary, linked control, and inline error. No note is saved. |
| Persistence | Stop and restart the dashboard, keeping its application-support directory. Sign in again if necessary. | Notes remain, belong to the same account, and cannot be read by another account. |
| API service | Run `mise run dev` in `Templates/api-service`. Request `/api/system/health`, then list and create `/api/v1/catalog/todos`. | Health returns JSON. Valid JSON creates a todo; empty or oversized titles return a client error. No UI is needed. |
| Chat | In `Templates/realtime-chat`, run `PORT=18081 mise run dev`; open `http://localhost:18081/en`. Create a passkey and send a message. | Connection state changes; the message appears and remains in history after reload. |

Passkey creation needs your browser authenticator. Use `localhost`, matching the starter's
relying-party ID; a different hostname is a different WebAuthn origin. Do not reuse real production
accounts or data for this exercise. API-service currently uses port 8080; stop conflicting local
services or run it with an explicit `ServerRuntime.start` address in your test application.

## Check the failure paths

- Cancel a passkey prompt, retry, sign out, and try a protected route. Cancellation must not sign
  you in; sign-out must revoke the session; unauthenticated requests must be rejected.
- Disable JavaScript after signing into dashboard. Reload, follow links, and submit a note form.
  Ordinary page and form work must still function. Passkey ceremonies and live WebSockets need JavaScript.
- Submit a form from an untrusted Origin and without a valid session. Neither request should mutate data.
- Submit malformed JSON, an unsupported content type, and an unknown path. Inspect the HTTP status
  and public error body; implementation errors and secrets must not appear.
- Open chat in two signed-in tabs. Send from each tab and confirm both see each message.
  Disconnect, reconnect, and inspect retained history. Broadcasting is local to one server process.
- Use only the keyboard through navigation, forms, and buttons. Check focus, accessible names,
  narrow-screen layout, browser zoom, and readable error feedback.
- Inspect browser console/network output. Default CSP must permit generated CSS without
  `unsafe-inline`; each JavaScript module must correspond to a selected typed capability.

## Exercise the public Swift API

1. Add a page with `Stack`, `Heading`, and `Text`; add responsive grouped style modifiers. Try to
   express your intended layout without looking up HTML tags or writing CSS.
2. Add a typed endpoint, a path parameter, validation, and a typed call site. Note every repeated
   route string, type annotation, or error that requires framework knowledge to understand.
3. Add a reusable form and compare its native validation with server validation. Try invalid input,
   missing fields, and an upload exceeding its limit.
4. Add localized content and metadata. Compare page title, canonical URL, social tags, and JSON-LD.
   Build twice with unchanged input and compare generated artifact hashes.
5. Replace in-memory data with SQLite, then run the same repository tests against PostgreSQL.
   Exercise rollback, a migration, KV expiration, and concurrent writes.
6. Add a preview, route test, and accessibility audit. Follow the relevant DocC example without
   reading framework implementation code.

For each friction point, send the smallest current call site, the call site you wanted, the expected
behavior, and the compiler/runtime message. Include whether the issue is naming, composition,
missing capability, repetition, or diagnostics.

## Automated checks

```sh
mise run check
```

Run `mise run test` inside each starter too. The CI matrix runs the framework and starter checks
on Linux and macOS. The default suite does not run live-provider tests unless opted in:

```sh
ROBIN_POSTGRES_TESTS=1 PGHOST=127.0.0.1 PGPORT=5432 PGUSER=postgres PGDATABASE=postgres mise run test -- --filter PostgresDatabaseTests
ROBIN_S3_TESTS=1 mise run test -- --filter liveS3ProviderConformance
```

Use a disposable PostgreSQL server and supply its test password through the environment when
required. The S3 fixture expects a local test service on port 59000 and the configuration recorded
in `Tests/RobinStorageTests/StorageTests.swift`. Never point destructive conformance fixtures at
production storage.
