# Changelog

## 1.0.0 — Unreleased

- Typed Swift components, grouped CSS modifiers, metadata, localization, and static builds.
- Typed HTTP routes, forms, persistent server and invocation transports, and deployment manifests.
- SQLite/PostgreSQL persistence, durable key-value storage, sessions, jobs, caching, email, and storage.
- Passkey authentication, optional magic links, and first-party integration packages.
- Four use-case starters: `blog`, `dashboard`, `api-service`, and `realtime-chat`.
- Shared static/SSR document metadata rendering and exact CSS hashes under the default CSP.
- Bounded HTTP/WebSocket ingress and rate-limit state; overflowing rate-limit capacity fails closed.
- Atomic KV compare-and-replace prevents overlapping starter saves from losing notes or messages.
- Shared `@FormModel`/`@Field` decoding for native forms, JSON, and uploads, with native constraints and accessible error redisplay.
- Bounded SMTP response buffering and release benchmarks for representative framework operations.
- Real HTTP transport conformance, PostgreSQL integration, starter matrix, and public DocC gates.
- Security fixes for authentication identity, proxy resolution, tenant storage, output containment, and web/email/event serialization.

### Migration from development snapshots

The former `static`, `ssr`, and `api` template names are replaced by the four use-case names above.
Existing applications keep their own source files; template selection does not configure application mode.
Exhaustive switches over `KeyValueWriteCondition` must handle the new `ifEqual` case.
Server page responses now include a complete HTML document, including merged metadata. Tests that
compared response bodies with a bare component fragment should assert the document's body content.
Custom Content-Security-Policy values remain unchanged; authorize your generated inline styles
explicitly when supplying a custom policy.
S3 object keys now use the same tenant-aware digest as local storage. Existing development-snapshot
objects must be migrated explicitly; Robin does not fall back to ambiguous legacy keys.
Changing an account's verified email invalidates old email lookups and pending magic links. Former
addresses remain reserved to that account until an atomic email-transfer workflow is available.
`Condition.has` accepts a constrained selector subset; unsupported syntax throws during compilation.
Message IDs must contain 1–64 ASCII letters, digits, hyphens, underscores, or periods.

This version remains unreleased until the release acceptance gates and publishing checks are complete.
