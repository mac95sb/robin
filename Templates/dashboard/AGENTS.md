# AGENTS.md

This application uses Robin's Controller → Service → Model → View architecture.

- Notes and conversations share `DashboardServices`, authentication, and SQLite storage. Keep notes scoped to their owner; the conversation channel is shared by signed-in accounts.

- A controller declares endpoints with `GET`, `POST`, `PUT`, `PATCH`, and `DELETE`. Add `Services`, `Models`, or `Theme` only when the application uses them.
- Keep application composition in `App.swift`; configure Robin tooling in `robin.pkl`.
- Keep the `main` method in `Site`; Robin owns the shared build and launch implementation.
- Use multiline string literals for prose that would wrap; put each modifier on its own line.
- Prefer semantic components, grouped style modifiers, standard Invoker Commands, and server round trips.
- Never conform application types directly to `APIRoute` or `ServerRoute`; those are framework implementation details.
- Never add a `*ClientModule`: use primitive state, Invoker Commands, or a framework-owned typed manifest record for an unavoidable browser capability.
- Do not invent raw HTML, CSS, or JavaScript escape hatches when Robin lacks a capability. Implement or request the missing typed Robin capability instead.
- Express interactions as semantic Robin actions. Do not choose runtime chunking or fabricate hidden command targets in application code.
- Keep generated output under `.robin/` and persistent application data outside it.
- Document public APIs, pages, and reusable components with DocC comments. Run `mise run docs` to generate the site; `.github/workflows/documentation.yml` publishes it to GitHub Pages.
