# ``RobinTooling``

Define the typed Robin framework, compiler, builder, test, and delivery policy loaded by the
`robin` command from a project's `robin.pkl` file.

Robin's command-line interface owns project scaffolding, builds, tests, linting, and environment
diagnostics. `App.swift` owns application composition and behavior; `robin.pkl` configures how Robin
compiles, checks, builds, and delivers it without overriding the application mode inferred from
registered pages and controllers.

## Run checks from the CLI

Run `robin lint` for project conventions, strict Swift formatting, and sizes from the last
`.robin/build/manifest.json`. The table reports actual uncompressed bytes grouped by media type,
counting each static artifact once. It does not estimate download time, compression, or per-page
requests. Rebuild after editing the application. Missing build output is explicitly reported as a
skipped performance check.

For a public deployment, run:

```sh
robin lint --url https://example.com --strategy mobile
robin lint --url https://example.com --strategy desktop --json
```

The optional URL audit sends the URL to Google's PageSpeed Insights service. Set
`PAGESPEED_API_KEY` in your environment when API quota requires a key. Keep it out of source control.
The results include Lighthouse's performance score, first and largest contentful paint, total
blocking time, speed index, and cumulative layout shift. These are lab measurements, not real-user
Core Web Vitals. Scores below 90 produce a warning. API failures fail the command; unavailable measurements are never reported as zero.
See [Google's PageSpeed Insights guide](https://developers.google.com/speed/docs/insights/v5/get-started).

A clean result says **Lint passed**, with error and warning counts. Warnings remain visible and
follow the configured lint severity; errors return a nonzero exit status. `--json` outputs only a
JSON diagnostic array, including numeric measurement values and units. Argument parsing errors
still follow the standard command-line usage-error format.

Run `robin doctor` to check tools and dependency resolution, and `robin test` to run Swift tests.
Lint success does not imply that behavior tests passed. Run `robin init` without arguments in an
interactive terminal for guided project creation, or provide a name and `--template` in scripts.

## Topics

### Start here

- <doc:Configure-Robin-Tooling>

### Policy

- ``ToolPolicy``
- ``ToolPolicyError``
