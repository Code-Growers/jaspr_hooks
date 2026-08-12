---
title: useState
description: Own reactive state with a ValueNotifier that rebuilds the component.
---

## What it does

`useState<T>(initialData)` creates a `ValueNotifier<T>`, subscribes the hook component to it, and disposes it automatically.

Read and write `.value`. A changed value schedules a rebuild; assigning an equal value follows `ValueNotifier` equality semantics and does not notify. The initial value is used only when the hook state is first created.

## Signature and parameters

```dart
ValueNotifier<T> useState<T>(T initialData)
```

`initialData` seeds the notifier once. The stable returned `ValueNotifier<T>` exposes reactive `.value`.

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

## Ownership and lifecycle

The hook creates, subscribes to, and disposes the notifier. Consumers must not dispose it themselves. Assignments after disposal follow the notifier's lifecycle contract and must be avoided.

## Server rendering

The initial value is rendered on the server. Use the same deterministic value for hydration, then change it from effects or events on the client.

## Common mistakes

Do not expect a changed `initialData` argument to reset preserved state. Avoid mutating a collection in place and reassigning the identical object; publish a new value or use a collection controller hook.

## Related APIs

Use `useReducer` for action-driven transitions. Use `useValueNotifier` when ownership is needed without an automatic rebuild subscription.
