# Developer Testing Guide

Use this as a menu, then record your results and desired API changes below. Final browser and
live-provider acceptance is deferred to a future session; unchecked items are not release sign-off.

| Goal | Start with |
| --- | --- |
| Quick confidence | Framework checks and one starter journey. Allow extra time for a cold build. |
| Developer experience | Build a small feature using only the public API and DocC; record friction. |
| Release acceptance | All four starters, failure paths, accessibility, restart behavior, and relevant providers. |

Run commands from the repository root unless they explicitly change directory. Use the tools
pinned in `mise.toml`.

Use a fresh generated project when judging the developer experience. Use the checked-in starters
when testing unpublished framework changes: their package dependency points at this checkout.
Run one server starter at a time, or assign dashboard/chat a different `PORT`.

## Start with the four journeys

These commands exercise this checkout. Each server command stays running: use a separate terminal
for each one and stop it with Control-C when finished.

```sh
# Build the static blog, then serve its output (requires Python 3 or another static server).
(cd Templates/blog && mise run dev)
python3 -m http.server 18082 --bind 127.0.0.1 --directory Templates/blog/.robin/build

# Run each server journey in its own terminal.
(cd Templates/dashboard && PORT=18080 mise run dev)
(cd Templates/realtime-chat && PORT=18081 mise run dev)
(cd Templates/api-service && mise run dev)
```

For the blog, open `http://localhost:18082/en/` and `http://localhost:18082/fr/`.

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

### API-service requests

With API-service running on port 8080, run these in another terminal:

```sh
curl -i http://localhost:8080/api/system/health
curl -i http://localhost:8080/api/v1/catalog/todos
curl -i http://localhost:8080/api/v1/catalog/todos/1

curl -i http://localhost:8080/api/v1/catalog/todos \
  -H 'Content-Type: application/json' -d '{"title":"Try Robin"}'

# Invalid input: expect 400 and no saved todo.
curl -i http://localhost:8080/api/v1/catalog/todos \
  -H 'Content-Type: application/json' -d '{"title":"   "}'

# Missing item: expect 404.
curl -i http://localhost:8080/api/v1/catalog/todos/999999
```

Successful requests should return JSON and a 2xx status. List the todos again to confirm the valid
creation. The API starter keeps a bounded in-memory list; restarting it resets that list.
Dashboard and chat use SQLite and should retain saved data across restarts.

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

This checks formatting, compilation, tests, and documentation for all 22 public modules.
For a smaller check while iterating, choose one:

```sh
mise run build
mise run test -- --filter FormTests
mise run test -- --filter PolarIntegrationTests
mise run docs
mise run benchmark
```

`mise run docs` generates `.robin/site`, including module reference archives. It fails on DocC
warnings and undocumented public symbols covered by the repository's coverage rule.

Run all starter tests against this checkout:

```sh
for starter in blog dashboard api-service realtime-chat; do
  (cd "Templates/$starter" && mise run test) || break
done
```

Check that all four starters ran and passed; the loop stops on the first failure.

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

## API ergonomics notebook

Try writing the call site you would expect **before** searching the documentation. Then compare it
with the working code. A compiler error, repeated type annotation, or unexpected parameter label
is useful feedback even when the framework behaves correctly.

| Area | Experiment | Notes / desired change |
| --- | --- | --- |
| App composition | Add a page and controller; assess inferred mode and service setup. | |
| Components and styling | Build a card with a heading, text, spacing, and responsive styles. | |
| Routing | Add a typed path parameter, request body, response, and error. | |
| Forms | Reuse a form model for native submission and JSON; inspect invalid and optional fields. | |
| Naming collisions | Use form APIs alongside `RobinHTML.Form`; note awkward qualification. | |
| Authentication | Add a protected action and sign-out flow; assess setup and errors. | |
| Persistence | Save a model, run a transaction, and switch database adapters. | |
| Services | Add a cached value, background job, email, or stored object. | |
| Content | Add a translation and metadata override; find the resulting output. | |
| Testing and DocC | Follow an example without opening framework implementation files. | |

### Change proposal — copy for each idea

**Title:**

**What I was trying to build:**

**Module / symbol / documentation page:**

**Current working call site (or the smallest failing example):**

```swift
// Paste the current API usage here.
```

**The call site I wish I could write:**

```swift
// Sketch the preferred API here; it does not need to compile yet.
```

**Expected behavior:**

**Actual behavior or exact compiler/runtime message:**

**Why this matters:** <!-- Readability, discoverability, repetition, composition, diagnostics, etc. -->

**How often I would use this:**

**Priority:** <!-- Must fix before adoption / important / nice to have -->

**Compatibility preference:** <!-- Additive overload / deprecate old API / breaking change acceptable -->

**Acceptance example:** <!-- An example that would prove the revised API feels right. -->

### Preferred conventions

- Names or argument labels I want to use consistently:
- Defaults that would remove repeated setup:
- Builder syntax that feels natural or awkward:
- Errors I want the compiler to catch earlier:
- Documentation examples I could not find:
- Three API changes that would make the biggest difference:

## Session results

**Date / commit:**

**OS / browser / Swift version:**

| Check or journey | Passed / failed / not run | Evidence, reproduction, or follow-up |
| --- | --- | --- |
| Framework automated checks | | |
| Four starter test suites | | |
| Blog and localization | | |
| Dashboard, passkeys, forms, restart | | |
| API service and invalid requests | | |
| Chat, two tabs, reconnect, restart | | |
| Keyboard, zoom, narrow screen, console | | |
| PostgreSQL / object storage | | |
| Hosted deployment / external provider sandbox | | |

**What felt great:**

**What slowed me down:**

**Changes I want next:**
