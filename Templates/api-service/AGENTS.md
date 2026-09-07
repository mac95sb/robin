# AGENTS.md

This API uses Robin controllers and models and registers no pages.

- Keep persistence private to its controller until multiple controllers need the same store.
- Keep application composition in `App.swift`; configure Robin tooling in `robin.pkl`.
- Keep the `main` method in `API`; Robin owns the shared build and launch implementation.
- Prefer HTTP semantics, standard Invoker Commands, and server round trips before adding browser runtime behavior.
- Do not invent raw HTML, CSS, or JavaScript escape hatches when Robin lacks a capability. Implement or request the missing typed Robin capability instead.
- Express interactions as semantic Robin actions. Do not choose runtime chunking or fabricate hidden command targets in application code.
- Keep generated output under `.robin/` and persistent application data outside it.
- Document public APIs and reusable types with DocC comments. Run `mise run docs` to generate the site or `mise run docs-preview` to view it locally; `.github/workflows/documentation.yml` publishes it to GitHub Pages.
