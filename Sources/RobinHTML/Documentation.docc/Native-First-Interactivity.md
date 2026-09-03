# Native-First Interactivity

Build interactions from HTML and CSS before opting into a Robin runtime capability.

## Choose the smallest behavior

Use this order:

1. Use a link, form, native control, disclosure, dialog, or CSS condition.
2. Use a standard Invoker Command when Robin exposes the required typed command.
3. Use a custom command only for a user action directed at an element that owns the behavior.
4. Use a capability-scoped runtime module for browser lifecycle or state that has no declarative form.

If Robin lacks the typed component or command you need, report that API gap. Do not substitute raw
HTML, CSS, JavaScript, or a generic script hook.

## Navigation

``Link`` performs an ordinary document navigation and works without JavaScript:

```swift
Navigation {
  Link("/about") { "About" }
}
```

A static application can explicitly enable same-origin client navigation:

```swift
struct Site: App {
  var clientNavigation: ClientNavigation { .enabled }
  var pages: some Pages { HomePage() }
}
```

The enhancement fetches and swaps complete static documents, synchronizes their Robin stylesheets,
updates browser history, and uses View Transitions when available. A failed enhancement falls back
to a full document navigation. Server-rendered applications retain normal server navigation.

## Forms and validation

Submit essential actions through a form so they work without a client runtime:

```swift
Form(action: "/subscribe") {
  Label(for: "email") { "Email" }
  Input(.email, name: "email", id: "email", accessibilityLabel: "Email")
  Button(.submit) { "Subscribe" }
}
```

The input kind selects the browser's native control and syntax validation. Treat server validation as
authoritative. Robin does not currently expose every HTML constraint as a typed initializer parameter;
add the missing typed capability before documenting or depending on it.

## Disclosure, dialogs, and commands

Use ``Disclosure`` for content that expands and collapses through native `<details>` behavior:

```swift
Disclosure(label: { "Shipping details" }) {
  Text { "Orders usually arrive within three days." }
}
```

``Dialog`` provides the typed dialog structure and initial open state. Typed popovers and standard
Invoker Commands are not yet part of Robin's public component surface. Until they are, keep an
essential action as a link or form round trip instead of adding application JavaScript.

## Responsive state and animation

`RobinStyle.Condition` compiles responsive and pseudo-state behavior into the CSS cascade:

```swift
import RobinStyle

Stack {
  Text { "Account" }
}
.padding(.sm)
.padding(.lg, on: .md)
```

Hover, focus, checked, open, color-scheme, container, and viewport conditions require no client state.
Typed keyframes, scroll timelines, anchor positioning, starting styles, and cross-document View
Transitions also remain native CSS. Unsupported animation is decorative fallback; it must not hide
content or an essential action.

## Server actions

Robin's public component surface does not yet bind `RobinRuntime.Action` values to controls. Use a
form and server round trip today. A later typed action boundary must preserve the same usable fallback
where the operation can be server-rendered.

## Approved JavaScript exceptions

JavaScript is limited to behavior the platform cannot perform declaratively:

- passkeys and other browser APIs without an HTML entry point;
- live WebSocket or server-sent-event document updates;
- immediate client-owned, optimistic, or collaborative state;
- composite widgets whose focus and keyboard semantics have no native equivalent;
- programmatic graphics, media, device, clipboard, notification, or file-system capabilities;
- service workers, offline behavior, background sync, push, and installation;
- explicitly enabled static client navigation; and
- custom Invoker Commands that handle a generated `CommandEvent`.

Each exception must be typed, capability-scoped, tree-shaken, and recorded in the build manifest.
Third-party behavior remains isolated inside ``Embed``. Preview and inspector scripts are development
tools and must not enter production output.

## Inspect an emitted runtime chunk

Run `robin build`, then inspect `.robin/build/manifest.json`. A JavaScript artifact's `scriptOrigin`
records whether Robin selected a direct capability, a custom command, or an application exception,
along with the API that selected it. No JavaScript artifact may exist without that explanation.

## See Also

- ``ClientNavigation``
- ``Form``
- ``Disclosure``
- ``Dialog``
- ``Embed``
