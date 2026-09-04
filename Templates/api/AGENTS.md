# AGENTS.md

This API uses Robin's Controller → Service → Model architecture and registers no pages.

- A `Route` or `APIRoute` is the controller. Add `Services` or `Models` only when the application uses them.
- Keep application composition in `App.swift`; configure Robin tooling in `robin.pkl`.
- Keep the `main` method in `Site`; Robin owns the shared build and launch implementation.
- Prefer HTTP semantics, standard Invoker Commands, and server round trips before adding browser runtime behavior.
- Do not invent raw HTML, CSS, or JavaScript escape hatches when Robin lacks a capability. Implement or request the missing typed Robin capability instead.
- Express interactions as semantic Robin actions. Do not choose runtime chunking or fabricate hidden command targets in application code.
- Keep generated output under `.robin/` and persistent application data outside it.
