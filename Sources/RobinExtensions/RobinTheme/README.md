# RobinTheme

RobinTheme is Robin's first-party theme and small component vocabulary for site applications.
Its included presets use browser generic font families, so importing it does not fetch or bundle
fonts.

```swift
import RobinTheme

var theme: any ApplicationTheme { Theme.robin }

RobinPage {
  RobinTitle { Heading { "Hello" } }
  RobinPanel { Text { "Welcome to Robin." }.padding(.lg) }
}
```

`RobinTheme` depends only on RobinHTML and RobinStyle, so static sites do not pull in the server or data runtime.
