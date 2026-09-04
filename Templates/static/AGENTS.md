# AGENTS.md

This application uses Robin's typed component and rendering model.

- Keep application structure proportional to the project. Static sites may need only `Views`.
- Keep application composition in `App.swift`; configure Robin tooling in `robin.pkl`.
- Keep the `main` method in `Site`; Robin owns the shared build and launch implementation.
- Prefer semantic components, grouped style modifiers, standard Invoker Commands, and server round trips.
- Do not invent raw HTML, CSS, or JavaScript escape hatches when Robin lacks a capability. Implement or request the missing typed Robin capability instead.
- Express interactions as semantic Robin actions. Do not choose runtime chunking or fabricate hidden command targets in application code.
- Keep generated output under `.robin/` and persistent application data outside it.
