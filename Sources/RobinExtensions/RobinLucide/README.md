# RobinLucide

RobinLucide provides a generated, type-safe Lucide icon catalog for Robin components.

```swift
import RobinLucide

Icon(.notebookPen, accessibilityLabel: "Notes")
```

The catalog is generated from Lucide 1.41.0. Regenerate it from an official Lucide source checkout:

```sh
python3 Scripts/generate-lucide.py path/to/lucide/icons \
  Sources/RobinExtensions/RobinLucide/LucideIcon+Catalog.swift
```

Lucide is licensed under the ISC License. See [LICENSE](LICENSE).

