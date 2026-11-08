# Forgejo Actions operations

These workflows target <https://git.maclong.dev/mac/robin>. They do not provision runners. The configuration checkout currently runs Forgejo natively on macOS and contains no Actions runner. Enabling Actions alone will not execute these jobs.

## Provision runners first

Register dedicated Forgejo runners with these label mappings:

| Workflow label | Runner registration label | Requirements |
| --- | --- | --- |
| `ubuntu-24.04` | `ubuntu-24.04:docker://ghcr.io/catthehacker/ubuntu:act-24.04` | Linux x86_64 Docker worker, Ubuntu 24.04 job image, Bash, Git, curl, CA roots, tar, gzip, Python 3, Node 20 for JavaScript actions, Docker CLI. Chromium dependency installation needs root or passwordless sudo inside the job container. |
| `macos` | `macos:host` | Dedicated native Apple Silicon macOS worker with Xcode command-line tools, Bash, Git, curl, Python 3, tar, and Node 20 for JavaScript actions. Not the Forgejo server account or workstation. |

The labels are explicit operator contracts, not a claim that hosted runners exist. Pin the Linux job image to an audited digest when provisioning the worker. The image above is an Ubuntu 24.04 Actions image, not plain `ubuntu:24.04`, which lacks JavaScript action prerequisites. Verify its current contents and install any missing prerequisites before registration. Configure a generous per-job disk quota for SwiftPM, documentation, starter builds, and Chromium; keep initial concurrency low.

For `provider-test`, allow the job container to access the worker's Docker socket and Docker CLI. The job must keep its default Docker container hostname (its container ID). The task starts PostgreSQL and Adobe S3Mock with `--network container:<job hostname>` so the Swift fixtures reach localhost without publishing worker ports. S3Mock creates `robin-tests` at startup. The worker daemon must be able to pull `postgres:17.5-alpine3.21` and `adobe/s3mock:4.11.0`; both are pinned to verified registry manifest digests in the task. These are disposable fixtures, not production services. They use public test-only credentials, no repository secrets, and no retained volumes. S3Mock is a live HTTP S3-compatible emulator, not AWS S3: this test does not prove IAM/signature enforcement, AWS networking, or production credentials. The initially considered MinIO/MC repositories denied anonymous pull access during implementation, so they are not CI dependencies.

**A Docker socket is host-equivalent access. A native macOS job is arbitrary code execution as the runner user.** Use disposable, isolated workers with no production credentials, no shared home directory, no access to the Forgejo server's files, no privileged access to the private network, and no shared writable caches. Require approval for external/fork pull requests before scheduling them. Reset/recreate workers between untrusted runs and trusted release runs. Merely setting `persist-credentials: false` is not isolation. Do not enable these labels on the existing Forgejo server process/account. The test containers clean up on ordinary exit and signals; the worker must also reap them after runner termination or host failure.

Allow outbound HTTPS to the Forgejo instance, `data.forgejo.org`, `code.forgejo.org`, GitHub and its release/content hosts, Swift downloads, mise's tool registries, npm, Playwright browser downloads, OS package mirrors, and the configured container registries. These dependencies download executable code. No application data or production credentials are required.

## Validation

`ci.yml` runs on main pushes, `v*` tag pushes, pull requests, and manual dispatch:

- `mise run check` (formatting, build, tests, **docs**, and offline release-tooling tests) and `mise run benchmark` on Linux and native macOS.
- `mise run test` inside each of the six starter directories. The framework, starters, and CI use Swift 6.4.2.
- `mise run provider-test`: live PostgreSQL repository/KV conformance, live HTTP S3-compatible storage conformance against S3Mock, invocation-runtime equivalence, and Vercel build-output conformance. Local runs use Docker loopback ports (S3 requires the fixture's fixed port 59000); CI shares the job network namespace. Readiness is bounded, failures include service logs, and containers are removed on exit.
- `mise run provider-test -- --wasi`: only the WASI toolchain probe, with **Swift 6.3.3 host + checksum-pinned Swift 6.3.3 SDK**, isolated build storage, and no attempt to build the Swift 6.4.2 framework against that SDK. This is not end-to-end WASI HTTP execution or a claim of Swift 6.4.2 WASI support.
- `mise run browser-test`: locked Playwright 1.56.1 and Node 24.21.0, fixture generation through `ROBIN_STATE_BROWSER_OUTPUT`, then Chromium checks for both state and navigation. CI passes `--install-deps` to install Chromium's Linux system libraries first. Locally, use that flag on Linux if libraries are missing; `PLAYWRIGHT_CHROMIUM_EXECUTABLE` can select an existing Chromium binary. npm dependencies, cache, and default browser downloads stay under ignored `.robin` output, not `Tests/Browser/node_modules` or the user's home directory.

Every job checks out the same resolved commit. External actions use full URLs and immutable commit pins; Forgejo's `v3-node20` artifact forks use the legacy artifact API instead of assuming GitHub's v4 backend exists. The mise action's automatic GitHub token and caches are disabled. The runner must support checkout v4 and Node 20 actions. Confirm artifact upload/download against the actual Forgejo/runner versions during the first run.

Docs are archived from `.robin/site` as `robin-docs.tar.gz`, retained for 14 days as a workflow artifact. The site currently assumes a `/robin` path prefix. **No docs deployment or hosting destination is configured or implied.** Publication includes the docs archive as a downloadable release asset through the release publishing task.

## Manual releases and reviewed notes

Tag pushes validate but **never publish**. There is no automatic AI-generated prose and no OpenAI credential in CI.

1. Review the release changes and commit final Markdown notes as `.forgejo/workflows/release-notes/vX.Y.Z.md` before tagging. The notes must be nonempty and committed in the tagged revision. This location is the tracked source; `.robin/releases` is ignored build output.
2. Merge to `main`, create/push the `vX.Y.Z` tag, and review its validation results. Protect `main`, release tags, workflow changes, and the tracked notes with review rules. Do not move release tags.
3. In Forgejo, dispatch **Validate and release** from `main`, setting `release_tag` to that exact tag. Leaving it empty runs validation only. A release request from another workflow ref/repository fails. The tag must resolve to a commit in `origin/main` history.
4. The workflow reruns all validation at the resolved tag commit. Only after every validation job passes does it run `mise run release-build -- --tag vX.Y.Z --test-starters` on Linux x86_64 and macOS arm64. Packaging must pass extracted-archive tests for all six generated starters. Linux arm64 is not built by this matrix.
5. The publish job downloads only artifacts from that same run, places native archives/checksums and `robin-docs.tar.gz` in `.robin/releases`, copies reviewed notes to `.robin/releases/vX.Y.Z.md`, creates `SHA256SUMS`, and calls `mise run release-publish -- vX.Y.Z`.

The release-build and release-publish tasks are owned separately; this workflow relies on those exact interfaces. `release-publish` must verify native archive checksums/provenance, include docs and checksums as assets, and use the Forgejo API at `https://git.maclong.dev`. Configure a least-privilege `FORGEJO_TOKEN` with release-write access to **only `mac/robin`**. It is passed only to the final publishing step, never to validation or PR jobs. Do not store it on runner disk or pass it through a workflow-wide environment variable. Limit dispatch and repository write access to trusted maintainers; repository administrators must enforce these protections before configuring the token. Forgejo feature support for environment approval/protected secrets varies, so this workflow does not assume GitHub environment protection exists.

There is no git commit, tag creation, release-note generation, or docs deployment in this workflow. Cancellation or validation failure must leave publication unstarted. A publish/API failure can still leave a partial release; inspect it before retrying according to the publishing task's behavior.
