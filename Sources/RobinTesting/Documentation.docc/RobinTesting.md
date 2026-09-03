# ``RobinTesting``

Test Robin applications through their typed render tree and transport-neutral responder.

Use ``RouteTestClient`` for route tests, ``AccessibilityAudit`` for structural accessibility
checks, and ``SnapshotTesting`` for deterministic text or image comparisons. Browser tests use
``BrowserSession`` with an explicit ``BrowserTestProfile``; JavaScript is disabled by default.

Create component examples with ``Preview(_:category:state:documentation:checks:content:)`` and collect them in a local
``PreviewDashboard`` beneath `.robin/preview`.

## Topics

### Start here

- <doc:Test-an-Application>

### Routes

- ``RouteTestClient``

### Snapshots

- ``SnapshotTesting``
- ``SnapshotError``

### Accessibility

- ``AccessibilityAudit``
- ``AccessibilityFinding``

### Browsers

- ``BrowserSession``
- ``BrowserSessionError``
- ``BrowserTestProfile``

### Previews

- ``Preview``
- ``Preview(_:category:state:documentation:checks:content:)``
- ``PreviewTheme``
- ``PreviewViewport``
- ``PreviewColorScheme``
- ``PreviewCheck``
- ``PreviewCheckResult``
- ``PreviewDashboard``
