---
title: useState
description: Own reactive state with a ValueNotifier that rebuilds the component.
---

## What it does

`useState<T>(initialData)` creates a `ValueNotifier<T>`, subscribes the hook component to it, and disposes it automatically.

Read and write `.value`. A changed value schedules a rebuild; assigning an equal value follows `ValueNotifier` equality semantics and does not notify. The initial value is used only when the hook state is first created.

## Usage

```dart
class Counter extends HookComponent {
  const Counter({super.key});

  @override
  Component build(BuildContext context) {
    final count = useState(0);

    return button(
      onClick: () => count.value++,
      [text('Count: ${count.value}')],
    );
  }
}
```

## Live demo

<HookDemo name="useState"/>

## Server rendering

The initial value is rendered on the server. Use the same deterministic value for hydration, then change it from effects or events on the client.

## Related APIs

Use `useReducer` for action-driven transitions. Use `useValueNotifier` when ownership is needed without an automatic rebuild subscription.

