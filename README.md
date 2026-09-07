<img src=".github/robin-logo.png" alt="Robin logo" width="96">

# Robin

[![CI](https://github.com/mac95sb/robin/actions/workflows/ci.yml/badge.svg?branch=main)](https://github.com/mac95sb/robin/actions/workflows/ci.yml)
[![Documentation](https://github.com/mac95sb/robin/actions/workflows/documentation.yml/badge.svg?branch=main)](https://mac95sb.github.io/robin/)
[![Swift 6.3](https://img.shields.io/badge/Swift-6.3-F05138?logo=swift&logoColor=white)](mise.toml)
[![Platforms](https://img.shields.io/badge/platforms-macOS%20%7C%20Linux-555555)](.github/workflows/ci.yml)

Build static sites, server-rendered applications, and HTTP APIs in Swift. Robin combines typed
components, CSS, routes, forms, persistence, and server services. Application behavior follows
the pages and controllers you register.

## Start a project

Use the Swift version pinned in `mise.toml`. From this checkout:

```sh
mise run build
mise exec -- swift run robin init MyBlog --template blog
cd MyBlog
mise run dev
```

The blog writes static files to `.robin/build`. Serve that directory with your static host and open
`/en/` or `/fr/`. The dashboard runs a server: open `http://localhost:8080/en` for the overview, `/en/notes` for notes or
`http://localhost:8080/en/conversations` for chat. Both share the same sign-in.

| Starter | Try it with |
| --- | --- |
| `blank` | One unstyled page at `/` and a JSON endpoint at `/api/v1/message` |
| `blog` | Markdown, metadata, localization, and static output with optional client enhancements |
| `marketing` | Product or portfolio site with live components, generated code examples, and a DocC link |
| `dashboard` | One workspace with passkey sign-in, private notes, shared conversations, usernames, and SQLite persistence |
| `api-service` | JSON requests to `/api/system/health` and `/api/v1/catalog/todos` |

Generated projects reference this repository's `main` branch during release preparation. Use a
released semantic version in your package dependency when adopting a stable release. The CLI
currently runs from source and needs the checkout's `Templates` directory, or `--templates`.

For the dashboard, use **localhost**, matching the passkey relying-party configuration.
Set the production HTTPS origin, relying-party ID, and security allowlist together before deployment.
The starter databases live in the application's support directory, outside generated `.robin` output.
Passkeys require browser JavaScript; already-authenticated native forms and page navigation do not.

## Validate changes

```sh
mise run check
```

This runs formatting, compilation, tests, and DocC coverage. `mise run docs` writes the public
site to `.robin/site`: marketing at `/robin/` and DocC under `/robin/reference/`.
The Docs link opens RobinCore directly; `/robin/docs/` redirects there for existing links.
The documentation workflow publishes them together.

Write DocC comments for public APIs, pages, and reusable components. The generated projects
include the same `mise run docs` task and a GitHub Pages workflow, so API reference and page or
component documentation stay next to their Swift source.
PostgreSQL and object-storage integration tests need their explicit test environment switches;
the default test run does not establish live-provider conformance.
