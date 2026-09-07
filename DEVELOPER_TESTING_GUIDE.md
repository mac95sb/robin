# Developer Testing Guide

v1.0.0 is not approved for release. Complete this walkthrough and resolve the API
feedback before creating a tag or publishing a release.

## Review each template

Use a fresh project for each review, created with the current checkout's CLI:

```sh
mise run build
ln -s "$HOME/Developer/robin/.build/debug/robin" "$HOME/.local/bin/robin"
robin init MyReview --template blank
```

Replace `blank` with `blog`, `marketing`, `dashboard`, or `api-service` and choose a
new project name. Generated packages currently reference GitHub `main`; to review
unpublished framework edits, point the generated package dependency at your local
Robin checkout. Run the generated project's documented mise tasks from its root.

| Template | Try | Confirm |
| --- | --- | --- |
| blank | Add a page, component, model field, and controller route | The smallest application is easy to understand and extend |
| blog | Write a Markdown post; change metadata, locale, and theme | Correct links, syntax highlighting, Blog/BlogPosting metadata, and static output |
| marketing | Switch examples and source tabs; edit counter, Boolean, and string state | Displayed Swift matches the preview; bindings and actions feel natural |
| dashboard | Sign up, sign out, sign in; create/edit/delete notes; send chat messages in two sessions | Authenticated views switch correctly, notes stay private, updates need no refresh, usernames are unique, messages survive reconnects |
| api-service | Call a route; add an endpoint; send invalid input | Routing, validation, errors, and response types are clear |

For each visual template, also try a narrow viewport, keyboard-only navigation,
EN/FR where supported, and system/light/dark appearance. Check the mobile menu,
focus visibility, empty states, validation errors, and browser console.

## Record API feedback

Copy this block for each change you want:

- Template and task:
- Current Swift call site:
- Preferred Swift call site:
- What felt awkward or surprising:
- Expected behavior:
- Priority: release blocker / improvement / later
- Result after revision:

## Before approving v1.0.0

- [ ] Reviewed all five templates from fresh projects.
- [ ] Resolved API feedback that blocks release.
- [ ] Ran `mise run check` and the generated templates' checks.
- [ ] Verified marketing and DocC on the published GitHub Pages site.
- [ ] Reviewed platform/provider claims against actual validation results.
- [ ] Reviewed the generated release notes and installation instructions.
- [ ] Explicitly approved the release tag and publication.

## Draft release notes

Communiqué uses `communique.toml` for every version. Set `OPENAI_API_KEY`,
`COMMUNIQUE_MODEL` (use `gpt-5.4-nano`), and
`GITHUB_TOKEN` in your shell or the repository’s ignored `.env` file. Keep credentials out of tracked files. This uses
separately billed API usage, not your ChatGPT subscription.

```sh
mise run release-notes          # Unpublished HEAD draft
mise run release-notes v1.0.0  # Version-specific draft
```

Replace the version for later releases. The task installs/uses pinned Communiqué
1.3.5 and writes `.robin/releases/<version>.md`, without creating a tag or release.
An absent tag uses HEAD, so commit intended changes before drafting. The first
release range excludes the root commit; review against current features too.
Dry runs skip link verification: check the generated links and claims yourself.

Stock Communiqué 1.3.5 is used without patches or a Rust build. GPT-5.4 nano
uses no reasoning by default, so it works with Communiqué’s Chat Completions
request format. Luna currently requires a reasoning setting the tool does not expose.

## Automatic tagged releases

Before the first tag, configure these GitHub Actions settings:

- Secret `OPENAI_API_KEY`: an API key with billing enabled.
- Variable `COMMUNIQUE_MODEL`: `gpt-5.4-nano`.

Pushing a version tag such as `v1.0.0` triggers `.github/workflows/release.yml`.
Only tag after completing the developer review. The workflow generates notes,
builds and smoke-tests the CLI, then publishes a GitHub release with:

- `robin-linux-x86_64.tar.gz` (Ubuntu 24.04 build).
- `robin-linux-aarch64.tar.gz` (Ubuntu 24.04 ARM build).
- `robin-macos-aarch64.tar.gz` (macOS 14+ Apple Silicon; no Intel build).
- `SHA256SUMS` for the archives.

Each archive includes the executable and all five templates. Keep
`Templates` beside the executable when installing manually. Linux archives link
the Swift standard library statically, but still depend on system libraries;
they are not universal Linux/static-musl builds. Swift and the generated project's
mise tools are still needed to build applications.

No release is published if notes or any build fail. Tags containing a prerelease
suffix, such as `v1.1.0-rc.1`, publish as prereleases. The workflow does not create
tags, and ordinary pushes to main do not publish releases.

References: [Communiqué](https://github.com/jdx/communique),
[OpenAI billing](https://help.openai.com/en/articles/9039756).
