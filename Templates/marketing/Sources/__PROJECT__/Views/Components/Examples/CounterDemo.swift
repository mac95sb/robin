import RobinHTML
import RobinRuntime
import RobinStyle

/// Demonstrates number state and button actions.
struct CounterDemo: Component {
  @State private var count = 0

  var body: ComponentContent {
    Form {
      Label(for: "demo-count") { "Make every click count." }.font(.emphasis)
      Stack {
        Button(accessibilityLabel: "Decrease count", action: #action { count -= 1 }) { "−" }
          .flex(justify: .center, align: .center)
          .frame(width: 44, height: 44).padding(.zero)
          .font(.label, color: .foreground)
          .font(color: .foreground, on: .dark)
          .background(color: .surface).background(color: .surface, on: .dark)
          .border(color: .border, radius: .md).border(color: .border, radius: .md, on: .dark)
          .background(color: .cardHover, on: .hover || .focus)
          .background(color: .cardHover, on: .dark && (.hover || .focus))
        Input(
          name: "count",
          value: $count,
          showsStepper: false,
          id: "demo-count",
          accessibilityLabel: "Count"
        )
        .frame(width: 64, height: 44).padding(.zero)
        .font(
          .title,
          color: .foreground,
          align: .center
        )
        .font(color: .foreground, on: .dark)
        .background(color: .cardHover).background(color: .cardHover, on: .dark)
        .border(color: .border, width: 0, radius: .md)
        Button(accessibilityLabel: "Increase count", action: #action { count += 1 }) { "+" }
          .flex(justify: .center, align: .center)
          .frame(width: 44, height: 44).padding(.zero)
          .font(.label, color: .foreground)
          .font(color: .foreground, on: .dark)
          .background(color: .surface).background(color: .surface, on: .dark)
          .border(color: .border, radius: .md).border(color: .border, radius: .md, on: .dark)
          .background(color: .cardHover, on: .hover || .focus)
          .background(color: .cardHover, on: .dark && (.hover || .focus))
      }
      .flex(justify: .center, align: .center, gap: .sm)
      Button(action: #action { count = 0 }) { "Reset counter" }.flex(align: .center, gap: .sm)
        .padding(.sm)
        .font(.label, color: .foreground, decoration: TextDecoration.none)
        .font(color: .foreground, on: .dark)
        .background(color: .surface).background(color: .surface, on: .dark)
        .border(color: .border, width: 0, radius: .sm)
        .font(color: .accent, on: .pressed)
        .font(color: .accent, on: .dark && .pressed)
        .background(color: .cardHover, on: .hover || .focus)
        .background(color: .cardHover, on: .dark && (.hover || .focus))
    }
    .flex(direction: .column, align: .center, gap: .md)
  }
  static let source = """
    import RobinHTML
    import RobinRuntime
    import RobinStyle

    /// Demonstrates number state and button actions.
    struct CounterDemo: Component {
      @State private var count = 0

      var body: ComponentContent {
        Form {
          Label(for: "demo-count") { "Make every click count." }.font(.emphasis)
          Stack {
            Button(accessibilityLabel: "Decrease count", action: #action { count -= 1 }) { "−" }
              .flex(justify: .center, align: .center)
              .frame(width: 44, height: 44).padding(.zero)
              .font(.label, color: .foreground)
              .font(color: .foreground, on: .dark)
              .background(color: .surface).background(color: .surface, on: .dark)
              .border(color: .border, radius: .md).border(color: .border, radius: .md, on: .dark)
              .background(color: .cardHover, on: .hover || .focus)
              .background(color: .cardHover, on: .dark && (.hover || .focus))
            Input(
              name: "count",
              value: $count,
              showsStepper: false,
              id: "demo-count",
              accessibilityLabel: "Count"
            )
            .frame(width: 64, height: 44).padding(.zero)
            .font(
              .title,
              color: .foreground,
              align: .center
            )
            .font(color: .foreground, on: .dark)
            .background(color: .cardHover).background(color: .cardHover, on: .dark)
            .border(color: .border, width: 0, radius: .md)
            Button(accessibilityLabel: "Increase count", action: #action { count += 1 }) { "+" }
              .flex(justify: .center, align: .center)
              .frame(width: 44, height: 44).padding(.zero)
              .font(.label, color: .foreground)
              .font(color: .foreground, on: .dark)
              .background(color: .surface).background(color: .surface, on: .dark)
              .border(color: .border, radius: .md).border(color: .border, radius: .md, on: .dark)
              .background(color: .cardHover, on: .hover || .focus)
              .background(color: .cardHover, on: .dark && (.hover || .focus))
          }
          .flex(justify: .center, align: .center, gap: .sm)
          Button(action: #action { count = 0 }) { "Reset counter" }.flex(align: .center, gap: .sm)
            .padding(.sm)
            .font(.label, color: .foreground, decoration: TextDecoration.none)
            .font(color: .foreground, on: .dark)
            .background(color: .surface).background(color: .surface, on: .dark)
            .border(color: .border, width: 0, radius: .sm)
            .font(color: .accent, on: .pressed)
            .font(color: .accent, on: .dark && .pressed)
            .background(color: .cardHover, on: .hover || .focus)
            .background(color: .cardHover, on: .dark && (.hover || .focus))
        }
        .flex(direction: .column, align: .center, gap: .md)
      }
    }
    """
}
