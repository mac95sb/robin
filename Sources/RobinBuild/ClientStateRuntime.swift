import Foundation
@_spi(Rendering) import RobinHTML

/// The shared browser interpreter selected automatically by state bindings.
/// Application code declares state and actions on components; it does not register this asset.
@_spi(Rendering) public struct ClientStateRuntime {
  /// The server route for the framework-owned runtime.
  public static let path = "/robin/state.js"

  /// Creates the shared runtime artifact for static and server delivery.
  /// - Returns: The browser-local state interpreter.
  /// - Throws: An asset validation error.
  public static func asset() throws -> BuildAsset {
    try BuildAsset(
      reference: path, path: "assets/robin-state.js", bytes: Array(source.utf8),
      mediaType: "text/javascript",
      scriptOrigin: .robinDirectCapability(.browserAPI, selectedBy: "State"))
  }

  /// The browser implementation shown by generated-code previews.
  public static let source = #"""
    (() => {
      const installed = Symbol.for("robin.state");
      if (document[installed]) return;
      document[installed] = true;
      const states = new Map();
      let body = document.body;
      const targets = ["text", "input", "hidden", "visible", "disabled"];
      const valid = (kind, value) => kind === "string" ? typeof value === "string"
        : kind === "boolean" ? typeof value === "boolean"
        : typeof value === "number" && Number.isFinite(value)
          && (kind !== "integer" || Number.isSafeInteger(value));
      function currentDocument() {
        if (body !== document.body) { body = document.body; states.clear(); }
      }
      function resolve(parts, store) {
        const [id, kind, initialJSON] = parts;
        if (typeof id !== "string" || !["string", "boolean", "integer", "number"].includes(kind)) throw Error("Invalid state");
        const initial = JSON.parse(initialJSON);
        if (!valid(kind, initial)) throw Error("Invalid initial value");
        if (!store.has(id)) store.set(id, { kind, initial, value: initial });
        const state = store.get(id);
        if (state.kind !== kind) throw Error("Incompatible state");
        return { id, state };
      }
      function read(element, target) {
        currentDocument();
        const raw = element.getAttribute(`data-robin-${target}`);
        if (raw === null) return null;
        try { return resolve(JSON.parse(raw), states); } catch { return null; }
      }
      function evaluate(expression, store, kind) {
        const [operation, lhs, rhs] = expression;
        let value;
        if (operation === "literal") value = JSON.parse(lhs);
        else if (operation === "state") {
          const reference = resolve(lhs, store);
          if (reference.state.kind !== kind) throw Error("Incompatible expression");
          value = reference.state.value;
        } else if (operation === "not" && kind === "boolean") value = !evaluate(lhs, store, kind);
        else if (operation === "add" && kind !== "boolean") value = evaluate(lhs, store, kind) + evaluate(rhs, store, kind);
        else if (operation === "subtract" && ["integer", "number"].includes(kind)) value = evaluate(lhs, store, kind) - evaluate(rhs, store, kind);
        if (!valid(kind, value)) throw Error("Invalid expression result");
        return value;
      }
      function run(element, target) {
        currentDocument();
        const raw = element.getAttribute(`data-robin-${target}`);
        if (raw === null) return;
        const pending = new Map([...states].map(([id, state]) => [id, { ...state }]));
        const changed = new Set();
        try {
          for (const [reference, operation, expression] of JSON.parse(raw)) {
            const { id, state } = resolve(reference, pending);
            let value;
            if (operation === "toggle" && state.kind === "boolean") value = !state.value;
            else if (operation === "set") value = evaluate(expression, pending, state.kind);
            if (!valid(state.kind, value)) throw Error("Invalid action result");
            state.value = value;
            changed.add(id);
          }
        } catch { return; }
        for (const id of changed) states.set(id, pending.get(id));
        for (const id of changed) publish(id);
      }
      function paint(element, target, value) {
        if (target === "text" && element.textContent !== String(value)) element.textContent = String(value);
        if (target === "hidden") element.hidden = value;
        if (target === "visible") element.hidden = !value;
        if (target === "disabled") element.disabled = value;
        if (target === "input") {
          if (element.type === "checkbox") element.checked = value;
          else if (element.value !== String(value)) element.value = String(value);
        }
      }
      // ponytail: scan bound elements per update; index subscriptions if large pages need it.
      function publish(id, source) {
        for (const target of targets) {
          for (const element of document.querySelectorAll(`[data-robin-${target}]`)) {
            const binding = read(element, target);
            if (binding?.id === id && !(element === source && target === "input")) {
              paint(element, target, binding.state.value);
            }
          }
        }
      }
      function hydrate(root) {
        if (body !== document.body) { body = document.body; states.clear(); }
        for (const target of targets) {
          const selector = `[data-robin-${target}]`;
          const elements = [...root.querySelectorAll(selector)];
          if (root instanceof Element && root.matches(selector)) elements.unshift(root);
          for (const element of elements) {
            const binding = read(element, target);
            if (binding) paint(element, target, binding.state.value);
          }
        }
      }
      hydrate(document);
      new MutationObserver(records => {
        if (body !== document.body) { hydrate(document); return; }
        for (const record of records) {
          for (const node of record.addedNodes) {
            if (node instanceof Element && node.isConnected) hydrate(node);
          }
        }
      }).observe(document.documentElement, { childList: true, subtree: true });
      document.addEventListener("click", event => {
        const button = event.target instanceof Element ? event.target.closest("button[data-robin-action]") : null;
        if (!button || button.matches(":disabled") || event.defaultPrevented) return;
        run(button, "action");
      });
      function updateInput(event) {
        const element = event.target;
        if (!(element instanceof HTMLInputElement) || element.matches(":disabled") || element.readOnly
          || event.defaultPrevented || !element.validity.valid) return;
        const binding = read(element, "input");
        if (binding) {
          const { id, state } = binding;
          const value = state.kind === "boolean" ? element.checked
            : state.kind === "string" ? element.value : element.valueAsNumber;
          if (!valid(state.kind, value)) return;
          state.value = value;
          publish(id, element);
        }
        run(element, event.type === "input" ? "edit" : "change");
      }
      document.addEventListener("input", updateInput);
      document.addEventListener("change", updateInput);
      document.addEventListener("reset", event => {
        queueMicrotask(() => {
          if (event.defaultPrevented || !(event.target instanceof HTMLFormElement)) return;
          for (const element of event.target.elements) {
            const binding = read(element, "input");
            if (!binding) continue;
            binding.state.value = binding.state.initial;
            publish(binding.id);
          }
        });
      });
    })();
    """#
}
