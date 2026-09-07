# AGENTS.md

This is a minimal Robin application with one app, page, controller, model, and component.

- Keep application composition in `App.swift`; Robin owns the shared build and launch implementation.
- Keep each concern in its own file. Add folders when they contain multiple related files.
- Use typed Robin components, routes, and modifiers. Do not invent raw HTML, CSS, or JavaScript escape hatches; implement or request the missing Robin capability instead.
- Add layout, styling, storage, authentication, and browser interactions only when the application needs them.
- Keep generated output under `.robin/`; configure tooling in `robin.pkl`.
- Document public APIs, pages, and reusable components with DocC comments. Run `mise run docs` to generate the site; `.github/workflows/documentation.yml` publishes it to GitHub Pages.
