#!/usr/bin/env python3
"""Generate RobinLucide's static catalog from an official Lucide source tree."""

from pathlib import Path
import subprocess
import sys
import xml.etree.ElementTree as ET


def swift_string(value: str) -> str:
    return '"' + value.replace("\\", "\\\\").replace('"', '\\"') + '"'


def member_name(stem: str) -> str:
    head, *tail = stem.split("-")
    return head + "".join(word[:1].upper() + word[1:] for word in tail)


def node(element: ET.Element) -> str:
    tag = element.tag.rsplit("}", 1)[-1]
    values = {key.rsplit("}", 1)[-1]: swift_string(value) for key, value in element.attrib.items()}
    if tag == "path":
        return f".path({values['d']})"
    if tag in ("polygon", "polyline"):
        return f".{tag}({values['points']})"
    if tag == "circle":
        fill = f", fill: {values['fill']}" if "fill" in values else ""
        return f".circle(cx: {values['cx']}, cy: {values['cy']}, r: {values['r']}{fill})"
    if tag == "ellipse":
        return f".ellipse(cx: {values['cx']}, cy: {values['cy']}, rx: {values['rx']}, ry: {values['ry']})"
    if tag == "line":
        return f".line(x1: {values['x1']}, y1: {values['y1']}, x2: {values['x2']}, y2: {values['y2']})"
    if tag == "rect":
        rx = values.get("rx", "nil")
        ry = values.get("ry", "nil")
        return f".rect(x: {values['x']}, y: {values['y']}, width: {values['width']}, height: {values['height']}, rx: {rx}, ry: {ry})"
    raise ValueError(f"Unsupported Lucide element: {tag}")


def generate(source: Path) -> str:
    declarations = []
    for path in sorted(source.glob("*.svg")):
        root = ET.parse(path).getroot()
        name = member_name(path.stem)
        title = path.stem.replace("-", " ").title()
        nodes = ",\n      ".join(node(child) for child in root)
        declarations.append(
            f"  /// The {title} icon.\n"
            f"  public static var `{name}`: Self {{\n"
            f"    .init([\n      {nodes}\n    ])\n"
            f"  }}"
        )
    if not declarations:
        raise ValueError(f"No SVG icons found in {source}")
    return (
        "// Generated from Lucide 1.41.0 by Scripts/generate-lucide.py. Do not edit.\n\n"
        "extension LucideIcon {\n"
        + "\n\n".join(declarations)
        + "\n}\n"
    )


if len(sys.argv) != 3:
    raise SystemExit("usage: generate-lucide.py <lucide-icons-directory> <output.swift>")
output = Path(sys.argv[2])
output.write_text(generate(Path(sys.argv[1])))
subprocess.run(["swift", "format", "format", "--in-place", str(output)], check=True)
