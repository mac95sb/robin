# ``RobinTheme``

Use Robin's first-party site theme and reusable page components.

All included presets use browser generic font families, so importing `RobinTheme` does not fetch
or bundle fonts.

## Overview

Assign ``RobinStyle/Theme/robin`` to an application, then use ``RobinPage`` for page framing and
``RobinPanel``, ``RobinLabel``, and ``RobinTitle`` for common presentation.

For a tighter, grid-led visual system, assign ``RobinStyle/Theme/modernist`` instead.
``RobinStyle/Theme/paper`` suits editorial content, ``RobinStyle/Theme/terminal`` suits technical
interfaces, and ``RobinStyle/Theme/playground`` is a colorful product preset.

```swift
import RobinTheme

var theme: any ApplicationTheme { Theme.robin }
```

## Topics

### Theme

- ``RobinStyle/Theme/robin``
- ``RobinStyle/Theme/modernist``
- ``RobinStyle/Theme/paper``
- ``RobinStyle/Theme/terminal``
- ``RobinStyle/Theme/playground``

### Components

- ``RobinPage``
- ``RobinPanel``
- ``RobinLabel``
- ``RobinTitle``
