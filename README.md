# Robin

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
`/en/` or `/fr/`. The other starters run a server; open `http://localhost:8080/en` for dashboard/chat.

| Starter | Try it with |
| --- | --- |
| `blog` | Markdown, metadata, localization, and static output without Robin JavaScript |
| `dashboard` | Passkey sign-in, native note forms, authenticated SSR, and SQLite persistence |
| `api-service` | JSON requests to `/api/system/health` and `/api/v1/catalog/todos` |
| `realtime-chat` | Passkey sign-in, persisted history, and a WebSocket connection |

Generated projects reference this repository's `main` branch during release preparation. Use a
released semantic version in your package dependency when adopting a stable release. The CLI
currently runs from source and needs the checkout's `Templates` directory, or `--templates`.

For dashboard and chat, use **localhost**, matching the passkey relying-party configuration.
Set the production HTTPS origin, relying-party ID, and security allowlist together before deployment.
The starter databases live in the application's support directory, outside generated `.robin` output.
Passkeys require browser JavaScript; already-authenticated native forms and page navigation do not.

## Validate changes

```sh
mise run check
```

This runs formatting, compilation, tests, and DocC coverage. `mise run docs` writes the public
reference site to `.robin/site/reference`. The documentation workflow publishes that directory.
PostgreSQL and object-storage integration tests need their explicit test environment switches;
the default test run does not establish live-provider conformance.

See the module DocC guides for deployment, security, native-first interaction, and persistence.
