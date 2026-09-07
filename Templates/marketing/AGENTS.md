# AGENTS.md

This marketing site uses Robin's typed content, component, and rendering model.

- Keep application structure proportional to the project. Keep reusable examples in `Examples` and page components in `Views`.
- Keep application composition in `App.swift`; configure Robin tooling in `robin.pkl`.
- Keep the `main` method in `Site`; Robin owns the shared build and launch implementation.
- Prefer semantic components, grouped style modifiers, standard Invoker Commands, and server round trips.
- Do not invent raw HTML, CSS, or JavaScript escape hatches when Robin lacks a capability. Implement or request the missing typed Robin capability instead.
- Express interactions as semantic Robin actions. Do not choose runtime chunking or fabricate hidden command targets in application code.
- Keep generated output under `.robin/` and persistent application data outside it.
- Document public pages and reusable components with DocC comments. Run `mise run docs` to generate the site; `.github/workflows/documentation.yml` publishes it to GitHub Pages.
