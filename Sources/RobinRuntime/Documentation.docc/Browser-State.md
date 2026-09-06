# Bind browser-local state

Declare state beside the component that uses it. Robin renders the initial values on the server and includes one shared browser runtime only on pages that contain bindings or actions.

```swift
import RobinHTML
import RobinRuntime

struct Counter: Component {
  @State private var count = 0

  var body: ComponentContent {
    Stack {
      Text { "Count: "; $count }
      Input(name: "count", value: $count, accessibilityLabel: "Count")
      Button(action: #action { count -= 10 }) { "−10" }
      Button(action: #action { count += 10 }) { "+10" }
      Button(action: #action { count = 0 }) { "Reset" }
    }
  }
}
```

No element IDs or script registration connect these controls. Native label associations may still use an input ID.
The generated HTML records typed state references and operations; the browser runtime updates text and native control properties without evaluating code strings.

## Values, bindings, and operations

Use `Bool`, `Int`, `Double`, or `String`. Integers must stay within ±9,007,199,254,740,991, and doubles must be finite. Invalid numeric edits leave state unchanged; the field remains editable. An action that would exceed those limits is ignored in full, without applying earlier assignments.

- `$value.set(newValue)` replaces a value of the same type.
- `$value.reset()` restores the declaration's initial value.
- `$flag.toggle()` reverses a Boolean.
- `#action { number += 10 }` and `#action { number -= 10 }` change a number using ordinary Swift operators.
- `Text { $value }` displays live text. Combine literal text and a binding in the builder for a label.
- `Input(name:value:accessibilityLabel:)` binds both ways. Booleans render checkboxes, numbers render number inputs, and strings render text inputs.
- `.hidden($flag)` and `.disabled($flag)` bind native visibility and disabled state. Apply disabled state to native controls that support it.

`count` outside an action reads or changes the Swift-side value used by the next render. Use `$count` for a live browser binding; ordinary Swift string interpolation of `count` is not reactive. Native form resets restore bound inputs unless the reset event is cancelled.

## Assign values and handle input changes

The `#action` macro translates supported Swift mutations into typed browser operations. Its closure does not execute on the server.

```swift
@State private var count = 0
@State private var amount = 0.0
@State private var name = ""
@State private var hasChanges = false

// Inside the component's body:
Button(action: #action {
  count = 42
  amount = 19.95
  name = "Robin"
  hasChanges = true
}) { "Apply values" }

Input(name: "name", value: $name, accessibilityLabel: "Name")
  .onInput(action: #action { hasChanges = true })
  .onChange(action: #action { name += "!" })
Text { "Unsaved changes" }.visible($hasChanges)
```

Actions support `=`, `+=`, `-=`, Boolean `toggle()`, and expressions containing state references, scalar literals, parentheses, `+`, `-`, and Boolean `!`. String `+` concatenates text. Assignments run in source order and can read values assigned earlier in the same action. Swift checks their types.

Use `.onInput(action:)` for each valid edit and `.onChange(action:)` for a committed change, such as leaving a text field. The input binding updates before its handler runs. Programmatic assignments and form resets do not trigger input handlers.

The macro deliberately rejects arbitrary function calls, control flow, and string interpolation. Reference state by `name` or `self.name` inside it; use `$name` when binding a component. `StateBinding` operations remain available when composing actions directly.

## Lifetime and boundaries

Each `State` declaration has its own identity. Independent component instances receive independent state; copying the same component value shares its declarations. Renderer-assigned identifiers are deterministic within a complete document.

Values live in memory for the current document and reset when navigation replaces the document or its body. Robin's client navigation uses a full document load when entering a stateful page without an installed state runtime. Updates to existing regions retain bindings from that document. Render related fragments together: identifiers from separately rendered documents must not be combined into one page.

Without JavaScript, initial text, values, and native inputs still render. Custom state actions do not run. State is local UI data, not persistence, authentication, or a server authorization boundary. Do not place secrets in it.

`StateAction` describes a browser operation. It does not serialize arbitrary Swift closures. Existing `StateStore`, `Binding`, and `Action` remain asynchronous Swift-side primitives; network requests and durable changes retain their explicit server APIs.

Native popovers, disclosures, and CSS conditions continue to use the browser's native behavior. They do not need application state simply to open, close, or respond to viewport changes.
