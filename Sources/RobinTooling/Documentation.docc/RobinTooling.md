# ``RobinTooling``

Define the typed Robin framework, compiler, builder, test, and delivery policy loaded by the
`robin` command from a project's `robin.pkl` file.

Robin's command-line interface owns project scaffolding, builds, tests, linting, and environment
diagnostics. `App.swift` owns application composition and behavior; `robin.pkl` configures how Robin
compiles, checks, builds, and delivers it without overriding the application mode inferred from
registered pages and controllers.

## Topics

### Start here

- <doc:Configure-Robin-Tooling>

### Policy

- ``ToolPolicy``
- ``ToolPolicyError``
