"""Assemble marketing, DocC navigation, and the legacy documentation redirect."""

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
destination = "/robin/reference/RobinCore/documentation/robincore/"
assert (site / "reference/RobinCore/documentation/robincore/index.html").is_file()
legacy = site / "docs/index.html"
legacy.parent.mkdir(parents=True, exist_ok=True)
legacy.write_text(
    '<!doctype html><html lang="en"><head><meta charset="utf-8">'
    f'<meta http-equiv="refresh" content="0;url={destination}">'
    '<title>Robin documentation</title></head><body>'
    f'<a href="{destination}">Open documentation</a></body></html>\n'
)
print(f"Assembled marketing, documentation redirect, and {len(pages)} DocC entry points.")
