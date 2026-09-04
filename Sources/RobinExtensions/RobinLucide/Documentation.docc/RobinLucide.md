# ``RobinLucide``

Render type-safe Lucide icons as inline vectors.

## Overview

Choose an icon from generated ``LucideIcon`` members and render it with ``Icon``. The catalog is
generated from Lucide 1.41.0, so misspelled icon names fail at compile time and unused members can be
removed by the linker.

```swift
import RobinLucide

Icon(.notebookPen, accessibilityLabel: "Notes")
Icon(.plus, size: 20)
```

Icons are decorative by default. Add an accessibility label only when nearby text does not already
communicate the icon's meaning.

## Topics

### Render an icon

- ``Icon``
- ``LucideIcon``

