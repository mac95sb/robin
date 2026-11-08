# Robin

[![Swift 6.4.2](https://img.shields.io/badge/Swift-6.4.2-F05138?logo=swift&logoColor=white)](mise.toml)
[![Platforms](https://img.shields.io/badge/platforms-macOS%20%7C%20Linux-555555)](.forgejo/workflows/ci.yml)

Build static sites, server-rendered applications, and HTTP APIs in Swift. Robin combines typed
components, CSS, routes, forms, persistence, and server services. Application behavior follows
the pages and controllers you register.

The canonical repository and release host is [Forgejo](https://git.maclong.dev/mac/robin).
The GitHub repository is a mirror. CI uses Forgejo Actions, not Buildkite or Entire.

## Start a project

Install the tools pinned in `mise.toml`. From this checkout:

```sh
mise run build
mise exec -- swift run robin init MyBlog --template blog
cd MyBlog
mise run dev
```

The blog writes static files to `.robin/build`. Serve that directory with your static host and open
`/en/` or `/fr/`. The dashboard runs a server: open `http://localhost:8080/en` for the overview,
`/en/notes` for notes, or `/en/conversations` for chat. Both features share the same sign-in.

| Starter | Try it with |
| --- | --- |
| `blank` | One unstyled page at `/` and a JSON endpoint at `/api/v1/message` |
| `blog` | Markdown, metadata, localization, and static output with optional client enhancements |
| `marketing` | Product or portfolio site with live components, generated code examples, and a DocC link |
| `dashboard` | One workspace with passkey sign-in, private notes, shared conversations, usernames, and SQLite persistence |
| `realtime-chat` | Authenticated WebSocket chat with persistent messages and reconnect handling |
| `api-service` | JSON requests to `/api/system/health` and `/api/v1/catalog/todos` |

Development builds generate a Swift package dependency on Forgejo's `main` branch. Official
release archives include version metadata: their generated projects use a semantic version
requirement for stable releases and an exact version for prereleases. Keep `robin`, `Templates`,
and `release.json` together when extracting an archive. You can select another template directory
with `--templates` or `ROBIN_TEMPLATES`.

The marketing template requires its canonical public URL so generated navigation, documentation
links, and static asset references work on any host:

```sh
mise exec -- swift run robin init MySite --template marketing --site-url https://example.com
```

Include any deployment subpath in that URL, for example `https://example.com/MySite`.

For the dashboard, use **localhost**, matching the passkey relying-party configuration.
Set the production HTTPS origin, relying-party ID, and security allowlist together before deployment.
Starter databases live in the application's support directory, outside generated `.robin` output.
Passkeys require browser JavaScript; already-authenticated native forms and page navigation do not.

## Validate changes

```sh
mise run check
```

This runs formatting, compilation, Swift tests, DocC coverage and sample validation, and the offline
release-tooling tests. Additional release checks are explicit:

```sh
mise run benchmark
mise run browser-test
mise run provider-test
mise run provider-test -- --wasi
mise run release-build -- --local --test-starters
```

- Browser tests install locked Playwright/Chromium dependencies under `.robin`. On Linux, add
  `--install-deps` if Chromium's system libraries are missing.
- Provider tests require Docker. They start disposable PostgreSQL and S3Mock containers and enable
  the live-provider tests that the default Swift test run skips. The S3 test checks HTTP storage
  behavior, not AWS IAM or signature enforcement.
- The WASI probe deliberately uses its own matching Swift 6.3.3 compiler and SDK. It does not
  establish end-to-end WASI hosting or Swift 6.4.2 WASI support.
- Packaging tests extract the CLI outside the checkout, generate all six starters, and optionally
  compile/test them against the packaged source. Builds may download SwiftPM dependencies.

Forgejo runs these checks on dedicated Linux and Apple Silicon macOS workers. Runners must be
provisioned before jobs can execute; they are not supplied by the Forgejo server. See
[runner and release operations](.forgejo/workflows/OPERATIONS.md) for labels, isolation,
network access, credentials, and the manual release gate.

## Documentation

Write DocC comments for public APIs, pages, and reusable components.

```sh
mise run docs
```

The combined static site is written to `.robin/site`: marketing at `/robin/` and DocC under
`/robin/reference/`. `/robin/docs/` redirects to RobinCore. Host that output at the `/robin` prefix;
serving it at another prefix requires updating the site's base-path configuration.

CI retains a documentation archive, and releases include `robin-docs.tar.gz`. **This repository
currently has no configured live documentation deployment.** Forgejo Actions does not imply
GitHub Pages or Forgejo Pages hosting. The generated starters retain an optional GitHub Pages
workflow for applications hosted there; it is not Robin's framework publication path.

## Prepare and publish a release

Release tags validate but do not publish automatically. A maintainer dispatches the Forgejo
workflow from `main` with an existing `release_tag`; every validation job must pass before
packaging and publishing start.

### 1. Generate and review notes before tagging

Communiqué is pinned to 1.5.0. Set `OPENAI_API_KEY` in your local environment or ignored `.env`.
`COMMUNIQUE_MODEL` optionally overrides the model in `communique.toml`.

```sh
mise run release-notes -- HEAD --label v1.0.0
```

This writes Markdown, an editable JSON draft, a coverage review, and a migration guide under
`.robin/releases/v1.0.0.*`. `--label` names files only; review the release title as well as the
claims, omissions, migration instructions, and links. For the first release, the task supplements
Communiqué's input with the root commit's metadata and patch. Its automatic coverage report still
uses an exclusive baseline range, so review the root supplement separately as the report warns.

**Generation sends repository context and selected code/diffs to OpenAI and incurs API charges,
even with Communiqué's `--dry-run`.** The task disables GitHub API tools and does not publish.
Communiqué's built-in publisher is GitHub-only; Robin uses the Forgejo API instead.

Copy approved Markdown to `.forgejo/workflows/release-notes/v1.0.0.md`, commit it with the release
changes, then create and push the matching version tag. Do not move published tags. Draft/review
files stay local; do not upload them as release assets or leave them in final artifact staging.

### 2. Dispatch the Forgejo release workflow

Configure a repository-scoped `FORGEJO_TOKEN` with release-write permission for `mac/robin`.
It is passed only to the publishing job, never to validation or pull-request jobs. From `main`,
dispatch **Validate and release** with `release_tag` set to the tag.

The workflow:

1. Resolves the tag to one commit in `main` history and checks committed reviewed notes.
2. Runs framework, starter, documentation, browser, provider, and benchmark checks.
3. Builds Linux x86_64 and macOS arm64 archives from the tag, with source provenance and SHA-256
   checksums, and tests all six generated starters from each extracted distribution.
4. Verifies both native archives, matching source snapshots, documentation, and reviewed notes.
5. Creates a Forgejo **draft**, uploads assets, then makes the release public only after uploads succeed.

Linux archives include static Swift libraries but are **not fully static binaries**; their OS/runtime
requirements are recorded in `runtime-libraries.txt`. Linux arm64 packaging is supported by the
local task but is not in the initial publishing matrix.

For local packaging and a publication preview, the corresponding tasks are:

```sh
mise run release-build -- --tag v1.0.0 --test-starters
mise run release-publish -- --dry-run v1.0.0
```

Publication requires a clean checkout and the exact staged asset set from the workflow, including
both platform archives, their checksum sidecars, docs, `SHA256SUMS`, and the approved Markdown.
The dry run is offline and never publishes. Existing releases—including incomplete drafts—are
never overwritten. If an upload fails, inspect the draft in Forgejo before removing it and retrying.
