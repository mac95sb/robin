# AGENTS.md

This application is an authenticated, persistent realtime chat service.

- Keep application composition in `App.swift`; configure Robin tooling in `robin.pkl`.
- Use controller route builders instead of conforming application types to framework transport protocols.
- Prefer semantic components, grouped style modifiers, and framework-owned typed client capabilities.
- Never add raw HTML, CSS, or JavaScript escape hatches. Implement or request the missing typed Robin capability.
- Keep generated output under `.robin/` and persistent application data outside it.
- Document public APIs, pages, and reusable components with DocC comments.
