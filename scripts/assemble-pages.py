"""Add Robin-rendered navigation to every DocC HTML entry point in the Pages artifact."""

from pathlib import Path
import re

root = Path(__file__).resolve().parents[1]
site = root / ".robin/site"
navigation = (root / ".robin/docc-navigation.html").read_text()
assert 'id="robin-site-navigation"' in navigation
for module in (site / "reference").iterdir():
    settings = module / "theme-settings.json"
    if module.is_dir() and not settings.exists():
        settings.write_text("{}\n")
pages = list((site / "reference").rglob("*.html"))
assert pages, "DocC pages must be built before assembly"
for path in pages:
    html = path.read_text()
    bodies = list(re.finditer(r"<body\b[^>]*>", html))
    assert len(bodies) == 1, f"Unexpected DocC HTML structure: {path}"
    # Outside DocC's application root, so its client-side navigation preserves these links.
    if 'id="robin-site-navigation"' not in html:
        offset = bodies[0].end()
        path.write_text(html[:offset] + navigation + html[offset:])
assert "Build for the web." in (site / "index.html").read_text()
assert "Reference and guides" in (site / "docs/index.html").read_text()
print(f"Assembled marketing, documentation index, and {len(pages)} DocC entry points.")
